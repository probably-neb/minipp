#include <stdio.h>
#include <stdlib.h>
struct _mini_Node
{
long _mini_val;
struct _mini_Node* _mini_prev;
struct _mini_Node* _mini_next;
};
long _mini_swapped;
long _mini_compare(struct _mini_Node* _mini_a, struct _mini_Node* _mini_b)
{
return (_mini_a->_mini_val-_mini_b->_mini_val);
}
void _mini_deathSort(struct _mini_Node* _mini_head)
{
long _mini_swapped;
long _mini_swap;
struct _mini_Node* _mini_currNode;
_mini_swapped = 1L;
while ((_mini_swapped==1L))
{
_mini_swapped = 0L;
_mini_currNode = _mini_head;
while ((_mini_currNode->_mini_next!=_mini_head))
{
if ((_mini_compare(_mini_currNode, _mini_currNode->_mini_next)>0L))
{
_mini_swap = _mini_currNode->_mini_val;
_mini_currNode->_mini_val = _mini_currNode->_mini_next->_mini_val;
_mini_currNode->_mini_next->_mini_val = _mini_swap;
_mini_swapped = 1L;
}
_mini_currNode = _mini_currNode->_mini_next;
}
}
}
void _mini_printEVILList(struct _mini_Node* _mini_head)
{
struct _mini_Node* _mini_currNode;
struct _mini_Node* _mini_toFree;
_mini_currNode = _mini_head->_mini_next;
printf("%ld\n", _mini_head->_mini_val);
free(_mini_head);
while ((_mini_currNode!=_mini_head))
{
_mini_toFree = _mini_currNode;
printf("%ld\n", _mini_currNode->_mini_val);
_mini_currNode = _mini_currNode->_mini_next;
free(_mini_toFree);
}
}
long _mini_main()
{
long _mini_numNodes;
long _mini_counter;
struct _mini_Node* _mini_currNode;
struct _mini_Node* _mini_head;
struct _mini_Node* _mini_previous;
_mini_swapped = 666L;
scanf("%ld", &_mini_numNodes);
if ((_mini_numNodes<=0L))
{
printf("%ld\n", -1L);
return -1L;
}
_mini_numNodes = (_mini_numNodes*1000L);
_mini_counter = _mini_numNodes;
_mini_head = malloc(sizeof(struct _mini_Node));
_mini_head->_mini_val = _mini_counter;
_mini_head->_mini_prev = _mini_head;
_mini_head->_mini_next = _mini_head;
_mini_counter = (_mini_counter-1L);
_mini_previous = _mini_head;
while ((_mini_counter>0L))
{
_mini_currNode = malloc(sizeof(struct _mini_Node));
_mini_currNode->_mini_val = _mini_counter;
_mini_currNode->_mini_prev = _mini_previous;
_mini_currNode->_mini_next = _mini_head;
_mini_previous->_mini_next = _mini_currNode;
_mini_previous = _mini_currNode;
_mini_counter = (_mini_counter-1L);
}
_mini_deathSort(_mini_head);
_mini_printEVILList(_mini_head);
return 0L;
}
int main(void)
{
   return _mini_main();
}

