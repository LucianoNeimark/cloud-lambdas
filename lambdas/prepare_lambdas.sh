# Delete all .zip files
rm *.zip

# Zip each .py file into a separate .zip file
for file in *.py; do
    zip "${file%.py}.zip" "$file"
done
