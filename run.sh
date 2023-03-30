git submodule update
cd spark
cargo xtask build --release
cd ..

zig build

rm -rf root

mkdir root
mkdir root/boot

cp spark/.hdd/spark-riscv-sbi-release.bin config
cp zig-out/bin/LSD root/boot
cp config/spark.cfg root/boot


qemu-system-riscv64 \
    -machine virt \
    -cpu rv64 \
    -smp 1 \
    -m 4G \
    -bios config/opensbi-riscv64-generic-fw_jump.bin \
    -kernel config/spark-riscv-sbi-release.bin \
    -device nvme,serial=deadbeff,drive=disk1 \
    -drive id=disk1,format=raw,if=none,file=fat:rw:./root \
    -serial mon:stdio \
    -nographic \
    -d int \
    -D debug.log