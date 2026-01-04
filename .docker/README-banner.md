# InvoicePlane Banner File

The `invoiceplane-banner.sh` file is used to display a custom banner when entering Docker containers.

## File Locations

The banner file exists in multiple locations due to Docker build context requirements:

- `.docker/invoiceplane-banner.sh` - The master copy
- `.docker/workspace/invoiceplane-banner.sh` - Copy for workspace container
- `.docker/php-fpm/invoiceplane-banner.sh` - Copy for php-fpm container

## Maintenance

When updating the banner, make sure to update all three copies:

```bash
cp .docker/invoiceplane-banner.sh .docker/workspace/
cp .docker/invoiceplane-banner.sh .docker/php-fpm/
```

This is necessary because Docker build contexts are set to individual service directories (`.docker/workspace` and `.docker/php-fpm`), and Docker cannot access files outside the build context using `../` paths.
