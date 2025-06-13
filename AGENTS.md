# 🤖 AI Agent Instructions: Repository Pattern Implementation

## 📋 **Mission Overview**
Implement clean architecture repository pattern in the Rufko Flutter app. This is a **massive application** with complex interdependencies. You must analyze the scope of each section and determine appropriate completion boundaries based on actual complexity discovered.

## 🎯 **Critical Success Criteria**
- ✅ **ZERO functionality lost** - Every feature must work exactly as before
- ✅ **ZERO new errors/warnings** - `flutter analyze` must be clean after each section
- ✅ **ALL tests pass** - Existing functionality cannot break
- ✅ **Complete each section 100%** before proceeding - No partial implementations
- ✅ **Validate exhaustively** - Test every affected component thoroughly

## 🧠 **Adaptive Section Planning**
**You decide section scope based on:**
- Number of files that need modification
- Complexity of interdependencies discovered
- Risk level of changes required
- Testing requirements for validation

**Section completion rules:**
- Only mark section complete when 100% validated
- If section becomes too large, split it further
- If section is too small, combine with next logical step
- Document your decision-making process

---

## 🚀 **PHASE 1: Environment & Discovery**

### **STEP 1A: Environment Check & Setup**
```bash
# Check if Flutter already installed
if command -v flutter &> /dev/null; then
    echo "Flutter already installed: $(flutter --version)"
    flutter doctor -v
else
    echo "Installing Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable ~/flutter
    export PATH="$PATH:$HOME/flutter/bin"
    flutter doctor -v
fi

# Verify environment is ready
flutter doctor --android-licenses || true
flutter config --enable-web
```

### **STEP 1B: Project State Analysis**
```bash
cd /path/to/rufko/project

# Capture current state
flutter clean
flutter pub get
flutter analyze > analysis_before.txt 2>&1
flutter test > tests_before.txt 2>&1 || true

# Test current functionality
flutter build web --release
flutter run -d chrome --debug &
FLUTTER_PID=$!
sleep 30  # Let app start
kill $FLUTTER_PID

echo "=== BASELINE CAPTURED ==="
echo "Analyze errors: $(grep -c 'error:' analysis_before.txt || echo 0)"
echo "Analyze warnings: $(grep -c 'warning:' analysis_before.txt || echo 0)"
echo "Test failures: $(grep -c 'FAILED:' tests_before.txt || echo 0)"
```

### **STEP 1C: Deep Architecture Discovery**
```bash
# Create comprehensive file inventory
find lib -name "*.dart" | grep -E "(provider|service|repository|controller)" > architecture_files.txt

echo "=== ARCHITECTURE ANALYSIS ==="
echo "Total Dart files: $(find lib -name "*.dart" | wc -l)"
echo "Provider files: $(find lib -name "*provider*.dart" | wc -l)"
echo "Service files: $(find lib -name "*service*.dart" | wc -l)"
echo "Controller files: $(find lib -name "*controller*.dart" | wc -l)"
echo "Model files: $(find lib -name "*.dart" -path "*/models/*" | wc -l)"
```

**Analyze each provider file and document:**
- Dependencies on DatabaseService
- Methods that directly call database operations
- Public API surface that UI components use
- Interdependencies between providers

**Create comprehensive mapping:**
```bash
# Document current data flow
mkdir -p docs/repository_migration
cat > docs/repository_migration/current_architecture.md << 'EOF'
# Current Architecture Analysis

## Data Flow
UI Components → Controllers → Providers → DatabaseService → Hive/Storage

## Provider Analysis
[Document each provider found and its database dependencies]

## Risk Assessment
[Identify high-risk areas based on complexity and interdependencies]

## Migration Strategy
[Based on actual findings, determine migration approach]
EOF
```

**Section 1 Completion Criteria:**
- [ ] Environment fully functional
- [ ] Baseline metrics captured (errors, warnings, test results)
- [ ] Complete architectural analysis documented
- [ ] All provider → database relationships mapped
- [ ] Migration strategy defined based on actual complexity
- [ ] Risk assessment complete

**✅ PHASE 1 COMPLETE - Document findings and proceed only when 100% validated**

---

## 🏗️ **PHASE 2: Repository Infrastructure**

### **STEP 2A: Determine Repository Scope**
Based on your analysis from Phase 1, decide:
- Which entities need repositories first (start with least dependent)
- How many repository interfaces to create in this phase
- Whether to tackle one domain at a time or multiple

**Decision Framework:**
```bash
# Count dependencies for each major entity
echo "=== DEPENDENCY ANALYSIS ==="
grep -r "Customer" lib --include="*.dart" | wc -l
grep -r "Product" lib --include="*.dart" | wc -l  
grep -r "Quote" lib --include="*.dart" | wc -l
grep -r "Template" lib --include="*.dart" | wc -l

# Determine starting point (lowest dependency count or most isolated)
```

### **STEP 2B: Create Repository Infrastructure**
Based on your analysis, create directory structure:

```bash
# Create base structure (adapt based on your analysis)
mkdir -p lib/features/{customers,products,quotes,templates}/{domain,data}/repositories

# Document your decisions
cat > docs/repository_migration/infrastructure_decisions.md << 'EOF'
# Infrastructure Decisions

## Repository Priority Order
[List order based on dependency analysis]

## Directory Structure Created
[Document what you created and why]

## Phase 2 Scope  
[Clearly define what will be completed in this phase]
EOF
```

### **STEP 2C: Create Base Repository Interfaces**
For the entities you've chosen to tackle in this phase:

1. **Analyze the DatabaseService methods** each entity uses
2. **Create abstract repository interface** with those exact methods
3. **Validate interface design** against actual usage patterns

```dart
// Example structure - adapt based on your findings
abstract class [Entity]Repository {
  // Include ONLY methods actually used by providers
  // Match exact signatures from DatabaseService
  // Add documentation explaining each method's purpose
}
```

**Section 2 Completion Criteria:**
- [ ] Directory structure created and documented
- [ ] Repository interfaces created for chosen entities
- [ ] All interfaces validated against actual DatabaseService usage
- [ ] `flutter analyze` shows no new errors
- [ ] Documentation explains all decisions made
- [ ] Scope clearly defined for next phase

**✅ PHASE 2 COMPLETE - Validate everything works before proceeding**

---

## 🔧 **PHASE 3: Repository Implementation**

### **STEP 3A: Assess Implementation Complexity**
For each repository interface created in Phase 2:
- Count how many DatabaseService methods need to be wrapped
- Identify any complex logic that needs to be preserved
- Check for error handling patterns that must be maintained

### **STEP 3B: Implement Repository Classes**
Create concrete implementations:

```dart
class [Entity]RepositoryImpl implements [Entity]Repository {
  final DatabaseService _databaseService;
  
  [Entity]RepositoryImpl(this._databaseService);
  
  // Implement each interface method
  // Preserve all existing logic and error handling
  // Add comprehensive documentation
}
```

**For each implementation:**
1. **Wrap existing DatabaseService calls** - don't change logic
2. **Preserve error handling** exactly as it exists
3. **Add logging/debugging** support
4. **Validate each method** works identically to direct database calls

### **STEP 3C: Create Repository Tests**
```dart
// Create test files for each repository
// Test both interface contract and implementation behavior
// Ensure compatibility with existing DatabaseService behavior
```

**Section 3 Completion Criteria:**
- [ ] All repository implementations completed
- [ ] Every method tested and validated
- [ ] Error handling preserved exactly
- [ ] Performance impact measured (should be negligible)
- [ ] `flutter analyze` clean
- [ ] All existing tests still pass

**✅ PHASE 3 COMPLETE - Implementation validated**

---

## 🔄 **PHASE 4: Provider Integration**

### **STEP 4A: Provider Migration Planning**
**This is the highest-risk phase.** For each provider that will be modified:

1. **Document current public API** - what controllers/UI components call
2. **Identify internal database calls** to be replaced with repository calls
3. **Plan migration order** - start with providers that have fewest dependents
4. **Create rollback strategy** for each provider

### **STEP 4B: Incremental Provider Migration**
**One provider at a time:**

1. **Create backup** of original provider
2. **Add repository injection** to provider constructor
3. **Replace DatabaseService calls** with repository calls ONE METHOD AT A TIME
4. **Test after each method change**
5. **Validate public API unchanged**

```dart
// Example migration pattern
class CustomerStateProvider extends ChangeNotifier {
  final DatabaseService database;
  final CustomerRepository _customerRepository;  // ADD
  
  CustomerStateProvider({required this.database}) {
    _customerRepository = CustomerRepositoryImpl(database);  // ADD
  }
  
  // Change methods one by one:
  // OLD: await database.saveCustomer(customer);
  // NEW: await _customerRepository.saveCustomer(customer);
}
```

### **STEP 4C: Validate Each Provider Migration**
After each provider migration:
```bash
# Run comprehensive validation
flutter analyze
flutter test
flutter build web --release

# Test UI functionality manually
flutter run -d chrome --debug
# Navigate through all features that use the migrated provider
# Verify identical behavior to before migration
```

**Section 4 Completion Criteria:**
- [ ] Each provider migrated successfully
- [ ] All UI functionality works identically
- [ ] Public APIs unchanged
- [ ] All tests pass
- [ ] Performance maintained
- [ ] Error messages unchanged

**✅ PHASE 4 COMPLETE - All providers migrated and validated**

---

## 🧪 **PHASE 5: Testing & Validation**

### **STEP 5A: Comprehensive Feature Testing**
Test every major application flow:
- Customer creation, editing, deletion
- Quote generation and management
- Product management
- Template operations
- Media handling
- Export/import functionality

### **STEP 5B: Performance Validation**
```bash
# Measure app performance before/after
flutter run --profile -d chrome
# Test loading times, response times
# Ensure no performance degradation
```

### **STEP 5C: Create Repository Usage Examples**
```dart
// Document how to use repositories for future development
// Create examples for testing repositories
// Document patterns for extending repositories
```

**Section 5 Completion Criteria:**
- [ ] All features tested and working
- [ ] Performance maintained or improved
- [ ] Documentation complete
- [ ] Examples created for future developers
- [ ] Migration guide written

**✅ PHASE 5 COMPLETE - Repository pattern fully implemented**

---

## 📊 **COMPLETION VALIDATION**

### **Final Validation Checklist:**
- [ ] `flutter analyze` completely clean
- [ ] All existing tests pass
- [ ] All new repository tests pass
- [ ] Manual testing of all features successful
- [ ] Performance benchmarks met
- [ ] Documentation complete
- [ ] No regressions identified

### **Success Metrics:**
```bash
# Compare before/after metrics
echo "=== BEFORE MIGRATION ==="
cat analysis_before.txt | grep -E "(error|warning)" | wc -l

echo "=== AFTER MIGRATION ==="
flutter analyze | grep -E "(error|warning)" | wc -l

echo "=== TESTS ==="
flutter test

echo "=== BUILD ==="
flutter build web --release
```

### **Deliverables:**
- [ ] Complete repository pattern implementation
- [ ] Clean architecture structure
- [ ] Comprehensive documentation
- [ ] Migration guide for future features
- [ ] Test coverage for all repositories
- [ ] Performance validation report

**🎉 MISSION COMPLETE - Repository pattern successfully implemented with zero regressions**