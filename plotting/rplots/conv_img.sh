for file in img-gen/*.pdf; do
    echo "$file>${file%.pdf}.png"
    magick -density 400 "$file" -quality 90 "${file%.pdf}_light.png"
done
mv img-gen/*.png ../../docs/figures/