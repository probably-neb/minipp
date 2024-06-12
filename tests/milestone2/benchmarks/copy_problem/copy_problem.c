#include <stdio.h>

void print(long int n)
{
    printf("%ld ", n);
}

void println(long int n)
{
    printf("%ld\n", n);
}

long int _mini_read()
{
    long int n = 0;
    scanf("%ld", &n);

    return n;
}

int main()
{
   long int end;
   long int y;
   long int i;

   end = _mini_read();

   i = 1;
   y = 0;
   while(i < end)
   {
     y = i;
     i = i + 1;
   }

   println(y);

   return 0;
}
