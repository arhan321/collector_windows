## Cara running project nya : 

### sebelum melakukan perintah apapun di terminal wajib ketik : 
```
cmd
```
### setiap mau build project nya harus call si BuildTools :
```
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
```
### jalankan CMAKE compile
```
cmake -S . -B build-win -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release -DRMS_ENABLE_YMCONNECT=ON -DCMAKE_TOOLCHAIN_FILE=D:/vcpkg/scripts/buildsystems/vcpkg.cmake -DVCPKG_TARGET_TRIPLET=x64-windows -DVCPKG_APPLOCAL_DEPS=ON
```
### selanjutnya running hasil compile nya 
```
.\build-win\rms_collector.exe --config config/collector.dojo.conf --real
```