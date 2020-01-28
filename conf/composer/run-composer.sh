#!/usr/bin/env sh

echo "Composer Version & Diagnose"
composer --version
composer diagnose
echo "Composer Install Vendor Files"
composer install --no-scripts
echo "Done... Composer Install"
