# How to Use

1. **Download Source Code**

   - Navigate to the android/src folder in this repository and download the source code. Modify the code according to your project requirements.

2. **Import DynamsoftMRZScannerBundle/dynamsoftmrzscannerbundle as a Module**

   - In Android Studio, go to File > New > Import Module.
   - Select the DynamsoftMRZScannerBundle/dynamsoftmrzscannerbundle directory and follow the prompts to add it to your project.

3. **Add the module dependency to your app's build.gradle file:**

   ```groovy
   dependencies {
       implementation project(':dynamsoftmrzscannerbundle')
   }
   ```

4. **Sync Your Project**

   - Sync the Gradle files to ensure the dependency is correctly loaded.
