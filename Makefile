$(shell mkdir -p build)

all: build/aerox.img

build/aerox.img: build/boot.bin build/two.bin
	dd if=/dev/zero of=build/aerox.img bs=512 count=2880
	dd if=build/boot.bin of=build/aerox.img bs=512 count=1 conv=notrunc
	dd if=build/two.bin of=build/aerox.img bs=512 seek=1 conv=notrunc

build/boot.bin: boot/boot.asm
	nasm -f bin boot/boot.asm -o build/boot.bin

build/two.bin: boot/two.asm
	nasm -f bin boot/two.asm -o build/two.bin

run: build/aerox.img
	qemu-system-i386 -drive format=raw,file=build/aerox.img

clean:
	rm -rf build