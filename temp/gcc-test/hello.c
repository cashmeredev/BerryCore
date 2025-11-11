/* Simple C test program for gcc-arm verification */
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    printf("Hello from gcc-arm on BlackBerry!\n");
    printf("Compiler: %s\n", __VERSION__);
    printf("Architecture: ARM\n");
    
    /* Test basic math */
    int a = 42;
    int b = 13;
    int sum = a + b;
    
    printf("Math test: %d + %d = %d\n", a, b, sum);
    
    /* Test dynamic memory */
    int *ptr = malloc(sizeof(int) * 10);
    if (ptr == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        return 1;
    }
    
    ptr[0] = 100;
    ptr[9] = 999;
    printf("Memory test: ptr[0]=%d, ptr[9]=%d\n", ptr[0], ptr[9]);
    
    free(ptr);
    
    printf("\n✓ All tests passed!\n");
    return 0;
}

