all: plot

plot: plot_coeffs plot_expr plot_ent gen
pdf: plot_coeffs_pdf plot_expr_pdf plot_ent_pdf

plot_coeffs_pdf: img-pdf/coeff_mean_qubits7.pdf
plot_expr_pdf: img-pdf/expr.pdf
plot_ent_pdf: img-pdf/ent.pdf

plot_coeffs: img-tikz/coeff_mean_qubits7.tex
plot_expr: img-tikz/expr.tex
plot_ent: img-tikz/ent.tex

gen: img-tikz
	sed -i "s/{coeff_real_imag/{img-tikz\/coeff_real_imag/g" img-tikz/coeff_real_imag*
	bash gen_img.sh

img-pdf/coeff%.pdf: layout.r plot_coeffs.r csv_data
	mkdir -p img-pdf
	Rscript plot_coeffs.r pdf

img-pdf/expr.pdf: layout.r plot_expr.r csv_data
	mkdir -p img-pdf
	Rscript plot_expr.r pdf

img-pdf/ent.pdf: layout.r plot_ent.r csv_data
	mkdir -p img-pdf
	Rscript plot_ent.r pdf

img-tikz/coeff%.tex: layout.r plot_coeffs.r csv_data
	mkdir -p img-tikz
	Rscript plot_coeffs.r

img-tikz/expr.tex: layout.r plot_expr.r csv_data
	mkdir -p img-tikz
	Rscript plot_expr.r

img-tikz/ent.tex: layout.r plot_ent.r csv_data
	mkdir -p img-tikz
	Rscript plot_ent.r

clean:
	rm -rf build img-tikz img-pdf img-gen

.PHONY: all pdf clean plot_coeffs plot_ent plot_expr
