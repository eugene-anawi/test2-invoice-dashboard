# Development Rules & Environment Management
# Real-Time E-Commerce Invoice Dashboard

**Version:** 1.0  
**Date:** July 27, 2025  
**Purpose:** Maintain consistency and quality across all development activities  
**Scope:** test2 - Real-Time Invoice Streaming Dashboard

---

## 📋 **Document Purpose**

This document establishes the development rules, environment management procedures, and quality standards for the test2 application. It ensures consistency across all project documentation and maintains alignment between requirements, technical implementation, and actual code.

---

## 🔄 **Document Synchronization Matrix**

### **Critical File Dependencies**

When modifying any of these files, **ALL** related files must be updated simultaneously:

| **Primary File** | **Must Update** | **Should Review** | **May Impact** |
|------------------|-----------------|-------------------|----------------|
| **PRD.md** | TECHNICAL.md, README.md | CHANGELOG.md, TESTING_INSTRUCTIONS.md | Code comments, API docs |
| **TECHNICAL.md** | PRD.md (architecture sections) | README.md, FIX_SUMMARY.md | Implementation files |
| **README.md** | None required | PRD.md, TECHNICAL.md | Package.json descriptions |
| **mix.exs** | README.md (dependencies) | PRD.md (tech stack), TECHNICAL.md | Config files |
| **Database Schema** | PRD.md (data requirements), TECHNICAL.md | TESTING_INSTRUCTIONS.md | Migration files |
| **Architecture Changes** | PRD.md, TECHNICAL.md, README.md | CHANGELOG.md | All implementation files |

### **Update Triggers**

**Immediate Updates Required When:**
- ✅ Adding new features or modules
- ✅ Changing system architecture or data flow
- ✅ Modifying user interface or user experience
- ✅ Updating technology stack or dependencies
- ✅ Changing performance characteristics or requirements
- ✅ Modifying API endpoints or data structures

**Documentation Lag Allowed (Max 1 Sprint):**
- 🟡 Minor bug fixes that don't affect functionality
- 🟡 Code refactoring without behavioral changes
- 🟡 Internal implementation optimizations
- 🟡 Development tooling updates

---

## 🚀 **Development Workflow Standards**

### **1. Branch Management**

#### **Branch Naming Convention:**
```
feature/[component]-[description]     # New features
bugfix/[issue-id]-[description]       # Bug fixes
hotfix/[critical-issue]               # Production fixes
docs/[document-name]-[change]         # Documentation only
refactor/[component]-[description]    # Code refactoring
test/[component]-[test-type]          # Testing improvements
```

#### **Branch Lifecycle:**
1. **Create** from `main` branch
2. **Develop** with regular commits following commit standards
3. **Test** locally with full test suite
4. **Document** changes in relevant files
5. **Push** and create pull request
6. **Review** including documentation completeness
7. **Merge** after approval and CI/CD success

### **2. Commit Message Standards**

#### **Format:**
```
[type]([scope]): [description]

[optional body]

[optional footer with breaking changes, closes #issue]

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>
```

#### **Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Code style changes (formatting)
- `refactor` - Code refactoring
- `test` - Adding or updating tests
- `chore` - Build process or auxiliary tool changes
- `perf` - Performance improvements
- `ci` - Continuous integration changes

#### **Scopes:**
- `streaming` - Invoice streaming system
- `ui` - User interface components
- `db` - Database related changes
- `api` - API endpoints
- `config` - Configuration changes
- `deps` - Dependency updates

### **3. Pre-Commit Checklist**

**Before Every Commit:**
- [ ] Code follows project style guidelines
- [ ] All tests pass (`mix test`)
- [ ] Code quality checks pass (`mix credo --strict`)
- [ ] Type checking passes (`mix dialyzer`)
- [ ] Documentation updated if needed
- [ ] CHANGELOG.md updated for user-facing changes
- [ ] Performance impact assessed

**Before Push:**
- [ ] Full test suite passes
- [ ] Integration tests pass
- [ ] Documentation synchronization complete
- [ ] Related files updated per synchronization matrix

---

## 📚 **Documentation-First Development**

### **Rule: Document Before Implement**

1. **Requirements Change** → Update PRD.md first
2. **Technical Design** → Update TECHNICAL.md
3. **Implementation** → Code follows documentation
4. **Testing** → Verify implementation matches docs
5. **Review** → Ensure docs and code align

### **Documentation Quality Standards**

#### **PRD.md Requirements:**
- ✅ Clear, testable acceptance criteria
- ✅ Updated architecture diagrams
- ✅ Performance requirements specified
- ✅ User interface specifications included
- ✅ Risk assessment current

#### **TECHNICAL.md Requirements:**
- ✅ Implementation details match PRD
- ✅ Code examples are current and functional
- ✅ Architecture diagrams reflect actual implementation
- ✅ Performance optimizations documented
- ✅ Browser compatibility verified

#### **README.md Requirements:**
- ✅ Quick start instructions work
- ✅ Dependencies list is current
- ✅ Feature descriptions match PRD
- ✅ Setup instructions are complete
- ✅ Troubleshooting section updated

---

## 🏗️ **Environment Management Rules**

### **1. Configuration Changes**

#### **When Changing Environment Configuration:**

**Config File Updates** (`config/*.exs`):
1. Update `config/dev.exs`, `config/prod.exs`, or `config/test.exs`
2. Update README.md setup instructions
3. Update TECHNICAL.md if architecture affected
4. Update `.env.example` if new environment variables
5. Test configuration in all environments

**Database Changes** (`priv/repo/migrations/*.exs`):
1. Create migration file
2. Update PRD.md data requirements section
3. Update TECHNICAL.md schema documentation
4. Update TESTING_INSTRUCTIONS.md
5. Test migration rollback capability

**Dependency Changes** (`mix.exs`, `package.json`):
1. Update dependency version
2. Update README.md installation instructions
3. Update PRD.md technology stack if major change
4. Update TECHNICAL.md if new capabilities
5. Test application functionality
6. Update CI/CD pipeline if needed

### **2. Development Environment Setup**

#### **New Developer Onboarding Checklist:**
- [ ] Clone repository
- [ ] Read PRD.md for project understanding
- [ ] Read TECHNICAL.md for implementation details
- [ ] Follow README.md setup instructions
- [ ] Read this DEVRULES.md file
- [ ] Set up development tools (Elixir, Node.js, PostgreSQL, Redis)
- [ ] Run full test suite
- [ ] Start both servers (Phoenix + Svelte)
- [ ] Verify both dashboards work (ports 4000 + 5173)

#### **Environment Validation Script:**
```bash
# Add to start_servers.sh
echo "Validating environment..."
mix deps.get
mix compile
mix test
cd dashboard && npm ci && npm run build && cd ..
echo "Environment validated successfully"
```

### **3. Deployment Environment Management**

#### **Staging Deployment:**
- [ ] All tests pass in CI/CD
- [ ] Documentation synchronized
- [ ] Performance benchmarks met
- [ ] Security scan passed
- [ ] Database migrations tested

#### **Production Deployment:**
- [ ] Code review completed
- [ ] Technical documentation updated
- [ ] Rollback plan documented
- [ ] Monitoring alerts configured
- [ ] Performance baseline established

---

## ✅ **Quality Assurance Framework**

### **1. Code Quality Gates**

#### **Never Commit Code That:**
- ❌ Fails any tests
- ❌ Has Credo warnings in strict mode
- ❌ Has Dialyzer type errors
- ❌ Lacks documentation for new public functions
- ❌ Reduces test coverage below 80%
- ❌ Has TODO comments without GitHub issues
- ❌ Contains hardcoded secrets or API keys

#### **Always Ensure:**
- ✅ New features have corresponding tests
- ✅ Documentation reflects actual behavior
- ✅ Error handling is implemented
- ✅ Logging is appropriate for debugging
- ✅ Performance impact is acceptable
- ✅ Security implications considered

### **2. Performance Standards**

#### **Monitoring Thresholds:**
- **Invoice Generation**: Must maintain 5/second consistently
- **Display Rate**: Must maintain 2/second smoothly
- **Memory Usage**: Must stay below 500MB during full cycle
- **Database Queries**: Must average <50ms response time
- **UI Responsiveness**: Must update within 100ms
- **WebSocket Latency**: Must stay below 50ms

#### **Performance Testing Required For:**
- Database schema changes
- New streaming processes
- UI component changes
- Configuration modifications
- Dependency updates

### **3. Security Requirements**

#### **Security Checklist:**
- [ ] No secrets in repository
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention
- [ ] XSS protection enabled
- [ ] CORS properly configured
- [ ] Rate limiting implemented
- [ ] Error messages don't leak information

---

## 🔧 **Troubleshooting & Maintenance**

### **1. Common Issues Resolution**

#### **Documentation Drift:**
**Problem**: Code and documentation don't match  
**Detection**: Code review checklist, automated tests  
**Resolution**: Update all files per synchronization matrix  
**Prevention**: Documentation-first development

#### **Environment Configuration Mismatch:**
**Problem**: Works locally but fails in CI/CD  
**Detection**: CI/CD pipeline failures  
**Resolution**: Validate environment setup script  
**Prevention**: Environment validation in setup script

#### **Performance Degradation:**
**Problem**: System doesn't meet performance standards  
**Detection**: Monitoring alerts, performance tests  
**Resolution**: Profile, optimize, document changes  
**Prevention**: Performance testing in CI/CD

### **2. Maintenance Procedures**

#### **Weekly Tasks:**
- [ ] Review and update dependencies
- [ ] Check documentation synchronization
- [ ] Review performance metrics
- [ ] Update security scans
- [ ] Clean up old branches

#### **Monthly Tasks:**
- [ ] Full documentation review
- [ ] Performance baseline update
- [ ] Security assessment
- [ ] Dependency vulnerability scan
- [ ] Backup testing

#### **Quarterly Tasks:**
- [ ] Architecture review
- [ ] Technology stack evaluation
- [ ] Documentation overhaul
- [ ] Performance optimization review
- [ ] Development process improvement

---

## 📈 **Continuous Improvement**

### **1. Process Evolution**

#### **When to Update DEVRULES.md:**
- New team members join
- Development process issues identified
- Tool or technology changes
- Project complexity increases
- Quality issues recurring

#### **Update Process:**
1. Identify process improvement need
2. Draft changes to DEVRULES.md
3. Review with team
4. Update related documentation
5. Communicate changes
6. Monitor effectiveness

### **2. Metrics & Monitoring**

#### **Development Metrics to Track:**
- Documentation synchronization rate
- Code review cycle time
- Test coverage trends
- Performance benchmark trends
- Bug discovery rate by stage

#### **Quality Metrics:**
- Documentation completeness score
- Code quality trends (Credo/Dialyzer)
- Test coverage percentage
- Performance standard adherence
- Security scan results

---

## 🎯 **Success Criteria**

### **Development Process Success:**
- ✅ Zero documentation drift incidents
- ✅ All code changes include documentation updates
- ✅ New developers productive within 1 day
- ✅ CI/CD pipeline success rate >95%
- ✅ Performance standards always met

### **Quality Assurance Success:**
- ✅ Test coverage maintained >80%
- ✅ Zero security vulnerabilities
- ✅ Code quality score consistently high
- ✅ Performance benchmarks always met
- ✅ Documentation accuracy >95%

---

## 📞 **Emergency Procedures**

### **Production Issues:**
1. **Assess Impact** - User-facing vs. internal
2. **Check Documentation** - Known issues, troubleshooting guides
3. **Implement Fix** - Hotfix branch if critical
4. **Update Documentation** - Add to troubleshooting section
5. **Post-Mortem** - Update processes to prevent recurrence

### **Documentation Emergency:**
1. **Identify Discrepancy** - Code vs. documentation mismatch
2. **Assess Impact** - Developer confusion, incorrect implementation
3. **Immediate Fix** - Update most critical documentation first
4. **Full Synchronization** - Complete all related file updates
5. **Process Review** - Identify why synchronization failed

---

## 📝 **File Change Log**

| **Date** | **Changed By** | **Files Modified** | **Reason** | **Related Issues** |
|----------|----------------|-------------------|------------|-------------------|
| 2025-07-27 | Claude | DEVRULES.md | Initial creation | Development process standardization |

---

**Remember: This document is living documentation. Update it as processes evolve and improve.**

---

*This DEVRULES.md serves as the authoritative guide for development environment management, ensuring consistency, quality, and maintainability throughout the project lifecycle.*