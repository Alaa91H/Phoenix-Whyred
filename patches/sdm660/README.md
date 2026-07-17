# SDM660 / SDM636 mainline patches

Forward-port من [sdm660-mainline/linux](https://github.com/sdm660-mainline/linux):

- clocks / GCC / GPUCC
- pinctrl
- interconnect
- DRM/MSM panel bring-up
- remoteproc / Wi-Fi board data

بعد `setup.sh` يمكن استخراج باتشات:

```bash
cd .src/sdm660-mainline
git format-patch -o ../../patches/sdm660 <base>..<tip>
```

ثم أعد كتابتها على شجرة GKI 6.18 (قد تحتاج تعديلات سياقية).
