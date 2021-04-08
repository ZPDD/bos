#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#include "lib_bos.h"

int main(void) {
    uint8_t x=5,y=10;
    char* string =
        "Hello C Programming World!\n\n"
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer nec "
        "odio. Praesent libero. Sed cursus ante dapibus diam. Sed nisi. Nulla "
        "quis sem at nibh elementum imperdiet. Duis sagittis ipsum. Praesent "
        "mauris. Fusce nec tellus sed augue semper porta. Mauris massa. "
        "Vestibulum lacinia arcu eget nulla. Class aptent taciti sociosqu ad "
        "litora torquent per conubia nostra, per inceptos himenaeos. ";
    char* string2 = "This is the second string.\n";
    char* string3 = "This is the third string.\n";
    char* string4 = "This is an X/Y string!!";


    clrscr();
    print(string);
    print(string2);
    print(string3);
    print_xy(x,y,string4);

    return 0;
}

//myos) AC_CONFIG_SUBDIRS(myos) ;;
