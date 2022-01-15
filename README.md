# Introduction 
SSH Jump farm for with AD in a docker container.

This container:
- Uses any AD account to bind to AD (no domain join required!)
- Enables SSH
- Allows SSH/sudo control
- Can run anywhere (including kubernetes)
- Uses a base ubuntu image

# To Run
1. Update variables in ./run.sh
2. Run it via:
```
./run.sh
```
3. Enjoy!

---

# Changelog

## 1.0.0 (January 15, 2021)

FEATURES:
- Initial release!

ENHANCEMENTS:

BUG FIXES:

---