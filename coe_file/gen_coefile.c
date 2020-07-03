#include <stdio.h>
#include <stdlib.h>
#define ROW 10243
#define COL 28
#define SEED 3571

int main( void ) {

  FILE *fd;
  fd = fopen("10243_29bit.coe","w");
  if (fd == NULL)
    {
      printf("cannot open\n");
      exit(1);
    }
  srandom(SEED);
  
  printf("srand(%d)\n", SEED);

  fprintf(fd, "memory_initialization_radix=16;\n");
  fprintf(fd, "memory_initialization_vector=\n");

  long int x = 0;
  for(int i = 0; i < ROW-1; i++) {
    x = (random() % 0x20000000);
    fprintf(fd, "%lx,\n", x);    
  }
  x = (random() % 0x20000000);
  fprintf(fd, "%lx;", x);

  fclose(fd);
  return 0;
}

