#include <stdio.h>
#include <stdlib.h>
struct _mini_intList
{
long _mini_data;
struct _mini_intList* _mini_rest;
};
long _mini_intList;
long _mini_length(struct _mini_intList* _mini_list)
{
if ((_mini_list==NULL))
{
return 0L;
}
return (1L+_mini_length(_mini_list->_mini_rest));
}
struct _mini_intList* _mini_addToFront(struct _mini_intList* _mini_list, long _mini_element)
{
struct _mini_intList* _mini_front;
if ((_mini_list==NULL))
{
_mini_list = malloc(sizeof(struct _mini_intList));
_mini_list->_mini_data = _mini_element;
_mini_list->_mini_rest = NULL;
return _mini_list;
}
_mini_front = malloc(sizeof(struct _mini_intList));
_mini_front->_mini_data = _mini_element;
_mini_front->_mini_rest = _mini_list;
return _mini_front;
}
struct _mini_intList* _mini_deleteFirst(struct _mini_intList* _mini_list)
{
struct _mini_intList* _mini_first;
if ((_mini_list==NULL))
{
return NULL;
}
_mini_first = _mini_list;
_mini_list = _mini_list->_mini_rest;
free(_mini_first);
return _mini_list;
}
long _mini_main()
{
struct _mini_intList* _mini_list;
long _mini_sum;
scanf("%ld", &_mini_intList);
_mini_sum = 0L;
_mini_list = NULL;
while ((_mini_intList>0L))
{
_mini_list = _mini_addToFront(_mini_list, _mini_intList);
printf("%ld ", _mini_list->_mini_data);
_mini_intList = (_mini_intList-1L);
}
printf("%ld ", _mini_length(_mini_list));
while ((_mini_length(_mini_list)>0L))
{
_mini_sum = (_mini_sum+_mini_list->_mini_data);
printf("%ld ", _mini_length(_mini_list));
_mini_list = _mini_deleteFirst(_mini_list);
}
printf("%ld\n", _mini_sum);
return 0L;
}
int main(void)
{
   return _mini_main();
}

