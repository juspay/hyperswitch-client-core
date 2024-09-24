#!/bin/bash

echo "Library generation process initiated."

echo "Generating artifacts for React Native Gradle Plugin."

# Navigate to the react-native gradle plugin and build and publish
cd node_modules/@react-native/gradle-plugin
./gradlew build
./gradlew publish

echo "Applying LibraryCreation Patch."

# Navigate to the Android folder and apply the patch
cd ../../../android
git apply libraryCreation.patch

# Remove unnecessary files
rm app/src/main/java/io/hyperswitch/MainActivity.kt
rm app/src/main/res/layout/main_activity.xml
rm app/src/main/res/values/styles.xml

echo "Generating artifacts for Hyperswitch Android SDK."

# Build and publish the library
./gradlew assembleRelease
./gradlew publish

cd maven/io/hyperswitch

# Function to sign files and create a bundle
process_version_directory() {
    local base_dir="$1"
    local version_dir="$2"
    
    cd "$version_dir" || return

    # Sign all relevant files in the version directory
    for file in *.{aar,pom,jar,module}; do
        [ -e "$file" ] || continue
        
        echo "Signing $file..."
        gpg --armor --output "${file}.asc" --detach-sign "$file"
    done

    # Create the ZIP bundle
    local base_name
    base_name=$(basename "$base_dir")
    local zip_name="${base_name}-$(basename "$version_dir")-bundle.zip"

    echo "Creating ZIP bundle for $zip_name..."
    zip -r "$zip_name" *.{aar,pom,jar,module} *-sources.jar *-javadoc.jar *.asc

    cd ..
}

# Process each library directory
for library_dir in */; do
    [ -d "$library_dir" ] || continue
    cd "$library_dir" || continue
    
    # Process each version directory
    for version_dir in */; do
        [ -d "$version_dir" ] || continue
        process_version_directory "$library_dir" "$version_dir"
    done
    
    cd ..
done

echo "Processing completed."