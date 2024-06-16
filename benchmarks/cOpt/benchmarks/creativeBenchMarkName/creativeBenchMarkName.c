#include <stdio.h>
#include <stdlib.h>
struct _mini_node
{
long _mini_value;
struct _mini_node* _mini_next;
};
struct _mini_node* _mini_buildList()
{
long _mini_input;
long _mini_i;
struct _mini_node* _mini_n0;
struct _mini_node* _mini_n1;
struct _mini_node* _mini_n2;
struct _mini_node* _mini_n3;
struct _mini_node* _mini_n4;
struct _mini_node* _mini_n5;
_mini_n0 = malloc(sizeof(struct _mini_node));
_mini_n1 = malloc(sizeof(struct _mini_node));
_mini_n2 = malloc(sizeof(struct _mini_node));
_mini_n3 = malloc(sizeof(struct _mini_node));
_mini_n4 = malloc(sizeof(struct _mini_node));
_mini_n5 = malloc(sizeof(struct _mini_node));
scanf("%ld", &_mini_n0->_mini_value);
scanf("%ld", &_mini_n1->_mini_value);
scanf("%ld", &_mini_n2->_mini_value);
scanf("%ld", &_mini_n3->_mini_value);
scanf("%ld", &_mini_n4->_mini_value);
scanf("%ld", &_mini_n5->_mini_value);
_mini_n0->_mini_next = _mini_n1;
_mini_n1->_mini_next = _mini_n2;
_mini_n2->_mini_next = _mini_n3;
_mini_n3->_mini_next = _mini_n4;
_mini_n4->_mini_next = _mini_n5;
_mini_n5->_mini_next = NULL;
return _mini_n0;
}
long _mini_multiple(struct _mini_node* _mini_list)
{
long _mini_i;
long _mini_product;
struct _mini_node* _mini_cur;
_mini_i = 0L;
_mini_cur = _mini_list;
_mini_product = _mini_cur->_mini_value;
_mini_cur = _mini_cur->_mini_next;
while ((_mini_i<5L))
{
_mini_product = (_mini_product*_mini_cur->_mini_value);
_mini_cur = _mini_cur->_mini_next;
printf("%ld\n", _mini_product);
_mini_i = (_mini_i+1L);
}
return _mini_product;
}
long _mini_add(struct _mini_node* _mini_list)
{
long _mini_i;
long _mini_sum;
struct _mini_node* _mini_cur;
_mini_i = 0L;
_mini_cur = _mini_list;
_mini_sum = _mini_cur->_mini_value;
_mini_cur = _mini_cur->_mini_next;
while ((_mini_i<5L))
{
_mini_sum = (_mini_sum+_mini_cur->_mini_value);
_mini_cur = _mini_cur->_mini_next;
printf("%ld\n", _mini_sum);
_mini_i = (_mini_i+1L);
}
return _mini_sum;
}
long _mini_recurseList(struct _mini_node* _mini_list)
{
if ((_mini_list->_mini_next==NULL))
{
return _mini_list->_mini_value;
}
else
{
return (_mini_list->_mini_value*_mini_recurseList(_mini_list->_mini_next));
}
}
long _mini_main()
{
struct _mini_node* _mini_list;
long _mini_product;
long _mini_sum;
long _mini_result;
long _mini_bigProduct;
long _mini_i;
_mini_i = 0L;
_mini_bigProduct = 0L;
_mini_list = _mini_buildList();
_mini_product = _mini_multiple(_mini_list);
_mini_sum = _mini_add(_mini_list);
_mini_result = (_mini_product-(_mini_sum/2L));
while ((_mini_i<2L))
{
_mini_bigProduct = (_mini_bigProduct+_mini_recurseList(_mini_list));
_mini_i = (_mini_i+1L);
}
printf("%ld\n", _mini_bigProduct);
while ((_mini_bigProduct!=0L))
{
_mini_bigProduct = (_mini_bigProduct-1L);
}
printf("%ld\n", _mini_result);
printf("%ld\n", _mini_bigProduct);
return 0L;
}
int main(void)
{
   return _mini_main();
}

