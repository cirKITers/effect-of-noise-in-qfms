from typing import Dict, Optional, List, Any
import pennylane as qml
import pennylane.numpy as np


class Entanglement:

    @staticmethod
    def meyer_wallach(
        evaluate: callable,
        n_qubits: int,
        params_shape: List[int],
        samples: int,
        seed: int,
        **kwargs: Any
    ) -> float:
        """
        Calculates the entangling capacity of a given quantum circuit
        using Meyer-Wallach measure.

        Parameters
        ----------
        evaluate : callable
            Function that evaluates the quantum circuit.
        n_qubits : int
            Number of qubits in the circuit.
        params_shape : List[int]
            Shape of the parameters array.
        samples : int
            Number of samples per qubit.
        seed : int
            Seed for the random number generator.
        **kwargs : Any
            Additional keyword arguments for the evaluate function.

        Returns
        -------
        float
            Entangling capacity of the given circuit.
        """

        def _meyer_wallach(n_qubits: int, samples: int, params: np.ndarray) -> float:
            """
            Calculates the Meyer-Wallach sampling of the entangling capacity
            of a quantum circuit.

            Parameters
            ----------
            n_qubits : int
                Number of qubits in the circuit.
            samples : int
                Number of samples to be taken.
            params : np.ndarray
                Parameters of the instructor

            Returns
            -------
            float
                Entangling capacity of the given circuit.
            """
            mw_measure = np.zeros(samples, dtype=complex)

            qb = list(range(n_qubits))

            for i in range(samples):
                U = evaluate(params=params[i], **kwargs)

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

        # TODO: maybe switch to JAX rng
        rng = np.random.default_rng(seed)
        p = rng.uniform(0, 2 * np.pi, size=(samples, *params_shape))

        entangling_capability = _meyer_wallach(
            n_qubits=n_qubits,
            samples=samples,
            params=p,
        )

        return float(entangling_capability)
