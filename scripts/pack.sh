#!/usr/bin/env bash
# Pack Image into AnyKernel3 zip for whyred
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT}/PROJECT.conf"
# shellcheck source=/dev/null
source "${ROOT}/scripts/ci-env.sh"

DIST="${ROOT}/${DIST_DIR}"
AK="${ROOT}/${ANYKERNEL_DIR}"
STAMP="$(date -u +%Y%m%d-%H%M%S)"
GIT_SHA="${GITHUB_SHA:-$(git -C "${ROOT}" rev-parse --short HEAD 2>/dev/null || echo local)}"
GIT_SHA="${GIT_SHA:0:7}"
ZIP_NAME="${ZIP_PREFIX}-${PROJECT_VERSION}-${STAMP}-${GIT_SHA}.zip"
FETCH_ANYKERNEL="${FETCH_ANYKERNEL:-0}"

has_image=0
for img in Image.gz-dtb Image.gz Image; do
  [[ -f "${DIST}/${img}" ]] && has_image=1
done
if [[ $has_image -eq 0 ]]; then
  echo "ERROR: no Image in ${DIST}. Build first."
  exit 1
fi

if [[ "${FETCH_ANYKERNEL}" == "1" ]] || ci_is_github; then
  if [[ ! -f "${AK}/tools/ak3-core.sh" ]]; then
    echo "==> Fetching AnyKernel3..."
    tmp="$(mktemp -d)"
    ci_git_clone "https://github.com/osm0sis/AnyKernel3.git" "${tmp}/ak3" "master" || \
      git clone --depth 1 https://github.com/osm0sis/AnyKernel3.git "${tmp}/ak3"
    [[ -f "${AK}/anykernel.sh" ]] && cp -a "${AK}/anykernel.sh" "${tmp}/whyred-ak.sh"
    mkdir -p "${AK}"
    cp -a "${tmp}/ak3/." "${AK}/"
    rm -rf "${AK}/.git"
    [[ -f "${tmp}/whyred-ak.sh" ]] && cp -a "${tmp}/whyred-ak.sh" "${AK}/anykernel.sh"
    rm -rf "${tmp}"
  fi
fi

mkdir -p "${AK}"
# Prefer Image.gz-dtb for 4.19 SDM660
rm -f "${AK}/Image.gz-dtb" "${AK}/Image.gz" "${AK}/Image"
for img in Image.gz-dtb Image.gz Image; do
  if [[ -f "${DIST}/${img}" ]]; then
    cp -a "${DIST}/${img}" "${AK}/"
    break
  fi
done
cp -a "${DIST}/"*.dtb "${AK}/" 2>/dev/null || true
[[ -f "${DIST}/dtbo.img" ]] && cp -a "${DIST}/dtbo.img" "${AK}/"

if [[ -d "${ROOT}/${MODULES_OUT}/lib/modules" ]]; then
  tar -C "${ROOT}/${MODULES_OUT}" -czf "${ROOT}/${DIST_DIR}/modules-${STAMP}.tar.gz" lib/modules
fi

cat > "${AK}/version" <<EOF
${PROJECT_NAME} ${PROJECT_VERSION}
track ${KERNEL_TRACK}
kernel ${KERNEL_VERSION}
device ${DEVICE_CODENAME}
git ${GIT_SHA}
built $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

# Ensure anykernel targets whyred
if [[ ! -f "${AK}/anykernel.sh" ]] || ! grep -q 'whyred' "${AK}/anykernel.sh" 2>/dev/null; then
  cat > "${AK}/anykernel.sh" <<'EOF'
### AnyKernel3 — whyred
properties() { '
kernel.string=Whyred Kernel
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
device.name1=whyred
device.name2=Whyred
device.name3=Redmi Note 5
device.name4=Redmi Note 5 Pro
'; }
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;
. tools/ak3-core.sh;
dump_boot;
write_boot;
EOF
fi

OUT_ZIP="${ROOT}/${DIST_DIR}/${ZIP_NAME}"
rm -f "${OUT_ZIP}"
(
  cd "${AK}"
  zip -r9 "${OUT_ZIP}" . -x "*.git*" -x "*.DS_Store"
)
cp -a "${OUT_ZIP}" "${ROOT}/${DIST_DIR}/${ZIP_PREFIX}-latest.zip"
echo "==> ${OUT_ZIP}"
ls -lh "${OUT_ZIP}"
