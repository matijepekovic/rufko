# Migration Services - DEPRECATED

## Status: MIGRATION COMPLETED

All data has been successfully migrated from Hive to SQLite. These migration services are now **DEPRECATED** and can be safely removed in future cleanup.

## Completed Migrations:
- ✅ Customer data 
- ✅ Product data
- ✅ Quote data  
- ✅ App Settings
- ✅ Template Categories
- ✅ PDF Templates & Field Mappings
- ✅ Message Templates
- ✅ Email Templates
- ✅ Project Media
- ✅ Roof Scope Data
- ✅ Custom App Data Fields
- ✅ Inspection Documents

## What was migrated:
- All model classes converted from Hive to SQLite
- All repositories created for SQLite operations
- All providers updated to use SQLite repositories
- All Hive annotations removed from models
- Database service updated to use SQLite only

## Next steps:
1. These migration files can be removed once Hive dependencies are completely purged
2. Hive dependencies have been removed from pubspec.yaml
3. Hive imports removed from main.dart
4. App now runs entirely on SQLite

## For developers:
If you need to check legacy migration logic, these files contain the conversion logic used during the transition from Hive to SQLite.