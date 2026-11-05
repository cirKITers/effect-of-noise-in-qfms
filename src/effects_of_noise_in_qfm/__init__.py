"""effects_of_noise_in_qfm"""

import jax

__version__ = "0.1"

# Use 64 bit floats (complex128 states) in all pipelines.
jax.config.update("jax_enable_x64", True)
