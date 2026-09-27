all: aerox.img

aerox.img: boot/boot.bin boot/two.bin
	dd if=/dev/zero of=aerox.img bs=512 count=2880
	dd if=boot/boot.bin of=aerox.img bs=512 count=1 conv=notrunc
	dd if=boot/two.bin of=aerox.img bs=512 seek=1 conv=notrunc

boot/boot.bin: boot/boot.asm
	nasm -f bin boot/boot.asm -o boot/boot.bin

boot/two.bin: boot/two.asm
	nasm -f bin boot/two.asm -o boot/two.bin

run: aerox.img
	qemu-system-i386 -drive format=raw,file=aerox.img

clean:
	rm -f boot/*.bin aerox.img