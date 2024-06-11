from typing import Dict, Optional, Tuple, Any
import pennylane as qml
import pennylane.numpy as np
import hashlib
import os

from disentangling_entanglement.helpers.ansaetze import Ansaetze


class Model:
    """
    A quantum circuit model.
    """

    def __init__(
        self,
        n_qubits: int,
        n_layers: int,
        circuit_type: str,
        data_reupload: bool = True,
    ) -> None:
        """
        Initialize the quantum circuit model.

        Args:
            n_qubits (int): The number of qubits in the circuit.
            n_layers (int): The number of layers in the circuit.
            circuit_type (str): The type of quantum circuit to use.
                If None, defaults to "no_ansatz".
            data_reupload (bool, optional): Whether to reupload data to the
                quantum device on each measurement. Defaults to True.
            tffm (bool, optional): Whether to use the TensorFlow Quantum
                Fourier Machine Learning interface. Defaults to False.
            state_vector (bool, optional): Whether to measure the state vector
                instead of the wave function. Defaults to False.

        Returns:
            None
        """
        self.n_qubits = n_qubits
        self.n_layers = n_layers
        self.data_reupload = data_reupload
        self.pqc = getattr(Ansaetze, circuit_type or "no_ansatz")

        if data_reupload:
            impl_n_layers = n_layers + 1  # we need L+1 according to Schuld et al.
        else:
            impl_n_layers = n_layers

        params_shape = (
            impl_n_layers,
            self.pqc(None, self.n_qubits),
        )
        self.params = np.random.uniform(0, 2 * np.pi, params_shape, requires_grad=True)

        self.dev = qml.device("default.mixed", wires=n_qubits)

        self.circuit = qml.QNode(self._circuit, self.dev)

    def _iec(
        self,
        inputs: np.ndarray,
        data_reupload: bool = True,
    ) -> None:
        """
        Creates an AngleEncoding using RY gates

        Args:
            x (np.ndarray): length of vector must be 1, shape (1,)
            data_reupload (bool): Whether to reupload the data for the IEC
                or not, default is True.

        Returns:
            None
        """
        if data_reupload:
            for q in range(self.n_qubits):
                qml.RX(inputs, wires=q)
        else:
            qml.RX(inputs, wires=0)

    def _circuit(
        self,
        inputs: np.ndarray,
        params: np.ndarray,
        noise_params: Optional[Dict[str, float]] = None,
        state_vector: bool = False,
    ) -> float:
        """
        Creates a circuit with noise.
        This involves, Amplitude Damping, Phase Damping and Depolarization.
        The Circuit consists of a PQC and IEC in each layer.

        Args:
            inputs (np.ndarray): input vector of size 1
            params (np.ndarray): weight vector of size n_layers*(n_qubits*3-1)
            noise_params (Optional[Dict[str, float]]): dictionary with noise parameters
                - "BitFlip": float, default = 0.0
                - "PhaseFlip": float, default = 0.0
                - "AmplitudeDamping": float, default = 0.0
                - "PhaseDamping": float, default = 0.0
                - "DepolarizingChannel": float, default = 0.0

        Returns:
            float: Expectation value of PauliZ(0) of the circuit.
        """
        if self.data_reupload:
            n_layers = self.n_layers - 1
        else:
            n_layers = self.n_layers

        for l in range(0, n_layers):
            self.pqc(params[l], self.n_qubits)

            if self.data_reupload or l == 0:
                self._iec(inputs, data_reupload=self.data_reupload)

            if noise_params is not None:
                for q in range(self.n_qubits):
                    qml.BitFlip(noise_params["BitFlip"], wires=q)
                    qml.PhaseFlip(noise_params["PhaseFlip"], wires=q)
                    qml.AmplitudeDamping(noise_params["AmplitudeDamping"], wires=q)
                    qml.PhaseDamping(noise_params["PhaseDamping"], wires=q)
                    qml.DepolarizingChannel(
                        noise_params["DepolarizingChannel"], wires=q
                    )

        if self.data_reupload:
            self.pqc(params[-1], self.n_qubits)

        if state_vector:
            return qml.density_matrix(wires=list(range(self.n_qubits)))
        else:
            return qml.expval(qml.PauliZ(wires=0))

    def __call__(self, *args: Any, **kwds: Any) -> Any:
        # Call forward method which handles the actual caching etc.
        return self._forward(*args, **kwds)

    def _forward(
        self,
        inputs: np.ndarray,
        params: Optional[np.ndarray] = None,
        noise_params: Optional[Dict[str, float]] = None,
        cache: Optional[bool] = False,
        state_vector: bool = False,
    ) -> np.ndarray:
        """Perform a forward pass of the quantum circuit.

        Args:
            inputs (np.ndarray): The input data.
            params (Optional[np.ndarray], optional): The weights of the quantum
                circuit. If None, uses the current weights of the Instructor instance.
                Defaults to None.
            noise_params (Optional[Dict[str, float]], optional): The noise parameters.
                Defaults to None.
            cache (Optional[bool], optional): Whether to cache the results. Defaults to False.

        Returns:
            np.ndarray: The output of the quantum circuit.
        """
        # the qasm representation contains the bound parameters, thus it is ok to hash that
        hs = hashlib.md5(
            repr(
                {
                    "n_qubits": self.n_qubits,
                    "n_layers": self.n_layers,
                    "pqc": self.pqc.__name__,
                    "dru": self.data_reupload,
                    "noise_params": noise_params,
                }
            ).encode("utf-8")
        ).hexdigest()

        result = None
        if cache:
            name = f"pqc_{hs}.npy"

            cache_folder = ".cache"
            if not os.path.exists(cache_folder):
                os.mkdir(cache_folder)

            file_path = os.path.join(cache_folder, name)

            if os.path.isfile(file_path):
                result = np.load(file_path)

        if result is None:
            # execute the PQC circuit with the current set of parameters
            result = self.circuit(
                inputs=inputs,
                params=params,
                noise_params=noise_params,
                state_vector=state_vector,
            )

        if cache:
            np.save(file_path, result)

        return result
