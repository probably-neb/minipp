#include <stdio.h>
#include <stdlib.h>
struct _mini_node
{
long _mini_data;
struct _mini_node* _mini_next;
};
struct _mini_tnode
{
long _mini_data;
struct _mini_tnode* _mini_left;
struct _mini_tnode* _mini_right;
};
struct _mini_i
{
long _mini_i;
};
struct _mini_myCopy
{
long _mini_b;
};
long _mini_a;
long _mini_b;
struct _mini_i* _mini_i;
struct _mini_node* _mini_concatLists(struct _mini_node* _mini_first, struct _mini_node* _mini_second)
{
struct _mini_node* _mini_temp;
_mini_temp = _mini_first;
if ((_mini_first==NULL))
{
return _mini_second;
}
while ((_mini_temp->_mini_next!=NULL))
{
_mini_temp = _mini_temp->_mini_next;
}
_mini_temp->_mini_next = _mini_second;
return _mini_first;
}
struct _mini_node* _mini_add(struct _mini_node* _mini_list, long _mini_toAdd)
{
struct _mini_node* _mini_newNode;
_mini_newNode = malloc(sizeof(struct _mini_node));
_mini_newNode->_mini_data = _mini_toAdd;
_mini_newNode->_mini_next = _mini_list;
return _mini_newNode;
}
long _mini_size(struct _mini_node* _mini_list)
{
if ((_mini_list==NULL))
{
return 0L;
}
return (1L+(_mini_size(_mini_list->_mini_next)));
}
long _mini_get(struct _mini_node* _mini_list, long _mini_index)
{
if ((_mini_index==0L))
{
return _mini_list->_mini_data;
}
return _mini_get(_mini_list->_mini_next, ((_mini_index-1L)));
}
struct _mini_node* _mini_pop(struct _mini_node* _mini_list)
{
_mini_list = _mini_list->_mini_next;
return _mini_list;
}
void _mini_printList(struct _mini_node* _mini_list)
{
if ((_mini_list!=NULL))
{
printf("%ld\n", _mini_list->_mini_data);
_mini_printList(_mini_list->_mini_next);
}
}
void _mini_treeprint(struct _mini_tnode* _mini_root)
{
if ((_mini_root!=NULL))
{
_mini_treeprint(_mini_root->_mini_left);
printf("%ld\n", _mini_root->_mini_data);
_mini_treeprint(_mini_root->_mini_right);
}
}
void _mini_freeList(struct _mini_node* _mini_list)
{
if ((_mini_list!=NULL))
{
_mini_freeList(_mini_list->_mini_next);
free(_mini_list);
}
}
void _mini_freeTree(struct _mini_tnode* _mini_root)
{
if (!((_mini_root==NULL)))
{
_mini_freeTree(_mini_root->_mini_left);
_mini_freeTree(_mini_root->_mini_right);
free(_mini_root);
}
}
struct _mini_node* _mini_postOrder(struct _mini_tnode* _mini_root)
{
struct _mini_node* _mini_temp;
if ((_mini_root!=NULL))
{
_mini_temp = malloc(sizeof(struct _mini_node));
_mini_temp->_mini_data = _mini_root->_mini_data;
_mini_temp->_mini_next = NULL;
return _mini_concatLists(_mini_concatLists(_mini_postOrder(_mini_root->_mini_left), _mini_postOrder(_mini_root->_mini_right)), _mini_temp);
}
return NULL;
}
struct _mini_tnode* _mini_treeadd(struct _mini_tnode* _mini_root, long _mini_toAdd)
{
struct _mini_tnode* _mini_temp;
if ((_mini_root==NULL))
{
_mini_temp = malloc(sizeof(struct _mini_tnode));
_mini_temp->_mini_data = _mini_toAdd;
_mini_temp->_mini_left = NULL;
_mini_temp->_mini_right = NULL;
return _mini_temp;
}
if ((_mini_toAdd<_mini_root->_mini_data))
{
_mini_root->_mini_left = _mini_treeadd(_mini_root->_mini_left, _mini_toAdd);
}
else
{
_mini_root->_mini_right = _mini_treeadd(_mini_root->_mini_right, _mini_toAdd);
}
return _mini_root;
}
struct _mini_node* _mini_quickSort(struct _mini_node* _mini_list)
{
long _mini_pivot;
long _mini_i;
struct _mini_node* _mini_less;
struct _mini_node* _mini_greater;
struct _mini_node* _mini_temp;
_mini_less = NULL;
_mini_greater = NULL;
if ((_mini_size(_mini_list)<=1L))
{
return _mini_list;
}
_mini_pivot = (((_mini_get(_mini_list, 0L)+_mini_get(_mini_list, ((_mini_size(_mini_list)-1L)))))/2L);
_mini_temp = _mini_list;
_mini_i = 0L;
while ((_mini_temp!=NULL))
{
if ((_mini_get(_mini_list, _mini_i)>_mini_pivot))
{
_mini_greater = _mini_add(_mini_greater, _mini_get(_mini_list, _mini_i));
}
else
{
_mini_less = _mini_add(_mini_less, _mini_get(_mini_list, _mini_i));
}
_mini_temp = _mini_temp->_mini_next;
_mini_i = (_mini_i+1L);
}
_mini_freeList(_mini_list);
return _mini_concatLists((_mini_quickSort(_mini_less)), _mini_quickSort(_mini_greater));
}
struct _mini_node* _mini_quickSortMain(struct _mini_node* _mini_list)
{
_mini_printList(_mini_list);
printf("%ld\n", -999L);
_mini_printList(_mini_list);
printf("%ld\n", -999L);
_mini_printList(_mini_list);
printf("%ld\n", -999L);
return NULL;
}
long _mini_treesearch(struct _mini_tnode* _mini_root, long _mini_target)
{
printf("%ld\n", -1L);
if ((_mini_root!=NULL))
{
if ((_mini_root->_mini_data==_mini_target))
{
return 1L;
}
if ((_mini_treesearch(_mini_root->_mini_left, _mini_target)==1L))
{
return 1L;
}
if ((_mini_treesearch(_mini_root->_mini_right, _mini_target)==1L))
{
return 1L;
}
else
{
return 0L;
}
}
return 0L;
}
struct _mini_node* _mini_inOrder(struct _mini_tnode* _mini_root)
{
struct _mini_node* _mini_temp;
if ((_mini_root!=NULL))
{
_mini_temp = malloc(sizeof(struct _mini_node));
_mini_temp->_mini_data = _mini_root->_mini_data;
_mini_temp->_mini_next = NULL;
return _mini_concatLists(_mini_inOrder(_mini_root->_mini_left), (_mini_concatLists(_mini_temp, _mini_inOrder(_mini_root->_mini_right))));
}
else
{
return NULL;
}
}
long _mini_bintreesearch(struct _mini_tnode* _mini_root, long _mini_target)
{
printf("%ld\n", -1L);
if ((_mini_root!=NULL))
{
if ((_mini_root->_mini_data==_mini_target))
{
return 1L;
}
if ((_mini_target<_mini_root->_mini_data))
{
return _mini_bintreesearch(_mini_root->_mini_left, _mini_target);
}
else
{
return _mini_bintreesearch(_mini_root->_mini_right, _mini_target);
}
}
return 0L;
}
struct _mini_tnode* _mini_buildTree(struct _mini_node* _mini_list)
{
long _mini_i;
struct _mini_tnode* _mini_root;
_mini_root = NULL;
_mini_i = 0L;
while ((_mini_i<_mini_size(_mini_list)))
{
_mini_root = _mini_treeadd(_mini_root, _mini_get(_mini_list, _mini_i));
_mini_i = (_mini_i+1L);
}
return _mini_root;
}
void _mini_treeMain(struct _mini_node* _mini_list)
{
struct _mini_tnode* _mini_root;
struct _mini_node* _mini_inList;
struct _mini_node* _mini_postList;
_mini_root = _mini_buildTree(_mini_list);
_mini_treeprint(_mini_root);
printf("%ld\n", -999L);
_mini_inList = _mini_inOrder(_mini_root);
_mini_printList(_mini_inList);
printf("%ld\n", -999L);
_mini_freeList(_mini_inList);
_mini_postList = _mini_postOrder(_mini_root);
_mini_printList(_mini_postList);
printf("%ld\n", -999L);
_mini_freeList(_mini_postList);
printf("%ld\n", _mini_treesearch(_mini_root, 0L));
printf("%ld\n", -999L);
printf("%ld\n", _mini_treesearch(_mini_root, 10L));
printf("%ld\n", -999L);
printf("%ld\n", _mini_treesearch(_mini_root, -2L));
printf("%ld\n", -999L);
printf("%ld\n", _mini_treesearch(_mini_root, 2L));
printf("%ld\n", -999L);
printf("%ld\n", _mini_treesearch(_mini_root, 3L));
printf("%ld\n", -999L);
printf("%ld\n", _mini_treesearch(_mini_root, 9L));
printf("%ld\n", -999L);
printf("%ld\n", _mini_treesearch(_mini_root, 1L));
printf("%ld\n", -999L);
printf("%ld\n", _mini_bintreesearch(_mini_root, 0L));
printf("%ld\n", -999L);
printf("%ld\n", _mini_bintreesearch(_mini_root, 10L));
printf("%ld\n", -999L);
printf("%ld\n", _mini_bintreesearch(_mini_root, -2L));
printf("%ld\n", -999L);
printf("%ld\n", _mini_bintreesearch(_mini_root, 2L));
printf("%ld\n", -999L);
printf("%ld\n", _mini_bintreesearch(_mini_root, 3L));
printf("%ld\n", -999L);
printf("%ld\n", _mini_bintreesearch(_mini_root, 9L));
printf("%ld\n", -999L);
printf("%ld\n", _mini_bintreesearch(_mini_root, 1L));
printf("%ld\n", -999L);
_mini_freeTree(_mini_root);
}
struct _mini_node* _mini_myCopy(struct _mini_node* _mini_src)
{
if ((_mini_src==NULL))
{
return NULL;
}
return _mini_concatLists(_mini_add(NULL, _mini_src->_mini_data), _mini_myCopy(_mini_src->_mini_next));
}
long _mini_main()
{
long _mini_i;
long _mini_element;
struct _mini_node* _mini_myList;
struct _mini_node* _mini_copyList1;
struct _mini_node* _mini_copyList2;
struct _mini_node* _mini_sortedList;
_mini_myList = NULL;
_mini_copyList1 = NULL;
_mini_copyList2 = NULL;
_mini_i = 0L;
while ((_mini_i<10L))
{
scanf("%ld", &_mini_element);
_mini_myList = _mini_add(_mini_myList, _mini_element);
_mini_copyList1 = _mini_myCopy(_mini_myList);
_mini_copyList2 = _mini_myCopy(_mini_myList);
_mini_sortedList = _mini_quickSortMain(_mini_copyList1);
_mini_freeList(_mini_sortedList);
_mini_treeMain(_mini_copyList2);
_mini_i = (_mini_i+1L);
}
_mini_freeList(_mini_myList);
_mini_freeList(_mini_copyList1);
_mini_freeList(_mini_copyList2);
return 0L;
}
int main(void)
{
   return _mini_main();
}

