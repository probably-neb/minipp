#include <stdio.h>
#include <stdlib.h>
struct _mini_IntList
{
long _mini_head;
struct _mini_IntList* _mini_tail;
};
struct _mini_IntList* _mini_getIntList()
{
struct _mini_IntList* _mini_list;
long _mini_next;
_mini_list = malloc(sizeof(struct _mini_IntList));
scanf("%ld", &_mini_next);
if ((_mini_next==-1L))
{
_mini_list->_mini_head = _mini_next;
_mini_list->_mini_tail = NULL;
return _mini_list;
}
else
{
_mini_list->_mini_head = _mini_next;
_mini_list->_mini_tail = _mini_getIntList();
return _mini_list;
}
}
long _mini_biggest(long _mini_num1, long _mini_num2)
{
if ((_mini_num1>_mini_num2))
{
return _mini_num1;
}
else
{
return _mini_num2;
}
}
long _mini_biggestInList(struct _mini_IntList* _mini_list)
{
long _mini_big;
_mini_big = _mini_list->_mini_head;
while ((_mini_list->_mini_tail!=NULL))
{
_mini_big = _mini_biggest(_mini_big, _mini_list->_mini_head);
_mini_list = _mini_list->_mini_tail;
}
return _mini_big;
}
long _mini_main()
{
struct _mini_IntList* _mini_list;
_mini_list = _mini_getIntList();
printf("%ld\n", (_mini_biggestInList(_mini_list)));
return 0L;
}
int main(void)
{
   return _mini_main();
}

