# iterate all *.png files in current directory
for file in *_light.png; do
    echo "$file"
  magick "$file" -transparent white -channel RGB -negate "${file/_light.png/_dark.png}"
done
