const { execSync } = require('child_process');

try {
  // Run the Angular build with production configuration
  execSync('ng build --configuration production', { stdio: 'inherit' });
} catch (error) {
  console.error('Build failed:', error);
  process.exit(1);
}