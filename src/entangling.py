from typing import Dict, Optional
import pennylane as qml
import pennylane.numpy as np


class Entangling:

    @staticmethod
    def meyer_wallach(
        self,
        samples_per_qubit: int,
        params: Optional[np.ndarray] = None,
        noise_params: Optional[Dict[str, float]] = None,
    ) -> float:
        """
        Calculates the entangling capacity of a given quantum circuit
        using Meyer-Wallach measure.

        Parameters
        ----------
        samples_per_qubit : int
            Number of samples per qubit.
        bf: float: The bit flip rate.
        pf: float: The phase flip rate.
        ad: float: The amplitude damping rate.
        pd: float: The phase damping rate.
        dp: float: The depolarization rate.
        params: optional, np.ndarray:
            Parameters of the instructor

        Returns
        -------
        float
            Entangling capacity of the given circuit.
        """

        def _meyer_wallach(n_qubits: int, samples: int, params: np.ndarray):
            """
            Calculates the Meyer-Wallach sampling of the entangling capacity
            of a quantum circuit.

            Parameters
            ----------
            n_qubits : int
                Number of qubits in the circuit.
            samples : int
                Number of samples to be taken.
            params: optional, np.ndarray:
                Parameters of the instructor

            Returns
            -------
            float
                Entangling capacity of the given circuit.
            """
            mw_measure = np.zeros(samples, dtype=complex)

            qb = list(range(n_qubits))

            for i in range(samples):
                U = self.instructor.forward(
                    0, params[i], noise_params=noise_params, cache=True
                )

                entropy = 0

                for j in range(n_qubits):
                    density = qml.math.partial_trace(U, qb[:j] + qb[j + 1 :])
                    entropy += np.trace((density @ density).real)

                mw_measure[i] = 1 - entropy / n_qubits

            mw = 2 * np.sum(mw_measure.real) / samples

            # catch floating point errors
            if mw < 0.0:
                mw = 0.0
            return mw

        circuit = self.instructor.model.circuit
        samples = samples_per_qubit * len(circuit.device.wires)

        if params is not None:
            assert params.shape == self.instructor.model.n_params, (
                "Parameter shape of instructor, and that provided for "
                "entangling capability should be equal, but are "
                f"{params.shape} and {self.instructor.model.n_params} "
                "respectively"
            )
            p = np.repeat(np.expand_dims(params, axis=0), samples, axis=0)
        else:
            p = self.rng.uniform(
                0, 2 * np.pi, size=(samples, *self.instructor.model.n_params)
            )

        # TODO: propagate precision to kedro parameters
        entangling_capability = _meyer_wallach(
            n_qubits=len(circuit.device.wires),
            samples=samples,
            params=p,
        )

        return float(entangling_capability)
