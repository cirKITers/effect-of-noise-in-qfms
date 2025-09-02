all: plot

plot: plot_expr plot_ent plot_coeffs_mean plot_coeffs_encoding plot_coherent plot_coeffs_all plot_training gen
pdf: plot_expr_pdf plot_ent_pdf plot_coeffs_mean_pdf plot_coeffs_encoding_pdf plot_coherent_pdf plot_coeffs_all_pdf plot_training_pdf
single_coeff: img-pdf/single/coeffs.pdf
single_expr: img-pdf/single/expr.pdf
single_ent: img-pdf/single/ent.pdf
single_train: img-pdf/single/training.pdf

plot_coeffs_pdf: img-pdf/coeff_real_imag_qubits6.pdf
plot_coeffs_all_pdf: img-pdf/coeff_mean_qubits5.pdf
plot_coeffs_mean_pdf: img-pdf/coeff_abs_mean.pdf
plot_coeffs_encoding_pdf: img-pdf/coeff_real_imag_encoding.pdf
plot_coherent_pdf: img-pdf/n_freqs.pdf
plot_expr_pdf: img-pdf/expr.pdf
plot_ent_pdf: img-pdf/ent.pdf
plot_training_pdf: img-pdf/training_mse.pdf

plot_coeffs: img-tikz/coeff_real_imag_qubits6.tex
plot_coeffs_all: img-tikz/coeff_mean_qubits5.tex
plot_coeffs_mean: img-tikz/coeff_abs_mean.tex
plot_coeffs_encoding: img-tikz/coeff_real_imag_encoding.tex
plot_coherent: img-tikz/n_freqs.tex
plot_expr: img-tikz/expr.tex
plot_ent: img-tikz/ent.tex
plot_training: img-tikz/training_mse.tex

gen: img-tikz
	if [ -a img-tikz/coeff_real_imag_encoding.tex ]; then \
		sed -i "s/{coeff_real_imag/{img-tikz\/coeff_real_imag/g" img-tikz/coeff_real_imag*; \
	fi;
	bash gen_img.sh

img-pdf/single/ent.pdf: layout.r csv_data/single/ent.csv plot_single.r
	mkdir -p img-pdf/single
	Rscript plot_single.r pdf

img-pdf/single/expr.pdf: layout.r csv_data/single/expr.csv plot_single.r
	mkdir -p img-pdf/single
	Rscript plot_single.r pdf

img-pdf/single/coeffs.pdf: layout.r csv_data/single/coeffs_stat.csv plot_single.r
	mkdir -p img-pdf/single
	Rscript plot_single.r pdf

img-pdf/single/training.pdf: layout.r csv_data/single/training.csv plot_single.r
	mkdir -p img-pdf/single
	Rscript plot_single.r pdf

img-pdf/coeff_real_imag_qubits6.pdf: layout.r plot_coeffs.r csv_data/coeffs_full_dims1_q6_AmplitudeDamping.csv
	mkdir -p img-pdf
	Rscript plot_coeffs.r pdf

img-pdf/coeff_mean_qubits6.pdf: layout.r plot_coeffs_mean.r csv_data/coeffs_stat_dims1.csv csv_data/coeffs_stat_dims2.csv
	mkdir -p img-pdf
	Rscript plot_coeffs_mean.r pdf

img-pdf/coeff_mean_qubits5.pdf: layout.r plot_coeffs_all.r csv_data/coeffs_stat_dims1.csv csv_data/coeffs_stat_dims2.csv
	mkdir -p img-pdf
	Rscript plot_coeffs_all.r pdf

img-pdf/coeff_real_imag_encoding.pdf: layout.r plot_coeffs_encoding.r csv_data/coeffs_enc_full_dims1.csv
	mkdir -p img-pdf
	Rscript plot_coeffs_encoding.r pdf

img-pdf/coeff_abs%.pdf: layout.r plot_coeffs_mean.r csv_data/coeffs_stat_dims1.csv csv_data/coeffs_stat_dims2.csv
	mkdir -p img-pdf
	Rscript plot_coeffs_mean.r pdf

img-pdf/n_freqs.pdf: layout.r plot_coherent.r csv_data/coeffs_stat_dims1.csv csv_data/coeffs_stat_dims2.csv
	mkdir -p img-pdf
	Rscript plot_coherent.r pdf

img-pdf/expr.pdf: layout.r plot_expr.r csv_data/expr.csv
	mkdir -p img-pdf
	Rscript plot_expr.r pdf

img-pdf/ent.pdf: layout.r plot_ent.r csv_data
	mkdir -p img-pdf
	Rscript plot_ent.r pdf

img-pdf/training_mse.pdf: layout.r plot_training.r csv_data/training.csv
	mkdir -p img-pdf
	Rscript plot_training.r pdf

img-tikz/coeff_mean_qubits6.tex: layout.r plot_coeffs_mean.r csv_data/coeffs_stat_dims1.csv csv_data/coeffs_stat_dims2.csv
	mkdir -p img-tikz
	Rscript plot_coeffs_mean.r

img-tikz/coeff_mean_qubits5.tex: layout.r plot_coeffs_all.r csv_data/coeffs_stat_dims1.csv csv_data/coeffs_stat_dims2.csv
	mkdir -p img-tikz
	Rscript plot_coeffs_all.r

img-tikz/coeff_real_imag_encoding.tex: layout.r plot_coeffs_encoding.r csv_data/coeffs_enc_full_dims1.csv
	mkdir -p img-tikz
	Rscript plot_coeffs_encoding.r

img-tikz/coeff_real_imag_qubits6.tex: layout.r plot_coeffs.r csv_data/coeffs_full_dims1_q6_AmplitudeDamping.csv
	mkdir -p img-tikz
	Rscript plot_coeffs.r

img-tikz/coeff_abs%.tex: layout.r plot_coeffs_mean.r csv_data/coeffs_stat_dims1.csv csv_data/coeffs_stat_dims2.csv
	mkdir -p img-tikz
	Rscript plot_coeffs_mean.r

img-tikz/n_freqs.tex: layout.r plot_coherent.r csv_data/coeffs_stat_dims1.csv csv_data/coeffs_stat_dims2.csv
	mkdir -p img-tikz
	Rscript plot_coherent.r

img-tikz/expr.tex: layout.r plot_expr.r csv_data/expr.csv
	mkdir -p img-tikz
	Rscript plot_expr.r

img-tikz/ent.tex: layout.r plot_ent.r csv_data
	mkdir -p img-tikz
	Rscript plot_ent.r

img-tikz/training_mse.tex: layout.r plot_training.r csv_data/training.csv
	mkdir -p img-tikz
	Rscript plot_training.r

clean:
	rm -rf build img-tikz img-pdf img-gen

.PHONY: all pdf clean plot_coeffs plot_ent plot_expr plot_coeffs_mean plot_coherent plot_coeffs_encoding plot_coeffs_all plot_training
