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
   long int times;
   long int x;
   long int y;

   long int temp;
   long int i;

   x = _mini_read();
   y = _mini_read();
   times = _mini_read();

   i = 0;
   while(i < times)
   {
     temp = x;
     x = y;
     y = temp;
     i = i + 1;
   }

   print(x);
   println(y);

   return 0;
}
