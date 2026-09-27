void main() {
    char* video_memory = (char*) 0xB8000;

    const char* message = "Kernel loaded";
    int i = 0;

    while (message[i] != '\0') {
        video_memory[i * 2] = message[i];
        video_memory[i * 2 + 1] = 0x0B;
        i++;
    }

    while (1) {
        __asm__("hlt");
    }
}
