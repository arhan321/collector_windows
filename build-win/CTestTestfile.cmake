# CMake generated Testfile for 
# Source directory: D:/RMS
# Build directory: D:/RMS/build-win
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(mock_json_dry_run "D:/RMS/build-win/rms_collector.exe" "--config" "D:/RMS/config/collector.conf" "--mock" "--once" "--dry-run")
set_tests_properties(mock_json_dry_run PROPERTIES  _BACKTRACE_TRIPLES "D:/RMS/CMakeLists.txt;93;add_test;D:/RMS/CMakeLists.txt;0;")
