#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include "linked_list.h"


inline node_t* getHeadNode(const list_t* list) {
    return list->head;
}

inline node_t* getTailNode(const list_t* list) {
    return list->tail;
}

inline void setHeadNode(list_t* list, node_t* node) {
    if (list->head)
        list->head->prev = node;
    
    node->next = list->head;
    node->prev = NULL;

    list->head = node;
    list->len++;
}

inline void setTailNode(list_t* list, node_t* node) {
    if (list->tail)
        list->tail->next = node;

    node->prev = list->tail;
    node->next = NULL;
    
    list->tail = node;
    list->len++;
}

inline void* getTailValue(const list_t* list) {
    return getTailNode(list)->value;
}

inline void* getHeadValue(const list_t* list) {
    return getHeadNode(list)->value;
}



static inline node_t* walkList(const list_t* list, size_t index) {
    if (!list)
        return NULL;

    if (index >= list->len)
        return NULL;

    node_t* current = list->head;
    for (size_t i = 0; i < index; i++) {
        current = current->next;

        // Should never happen on a well formed list.
        if (!current)
            return NULL;
    }

    return current;
}

void* getValue(const list_t* list, size_t i) {
    if (!list)
        return NULL;

    node_t* node = walkList(list, i);
    if (!node)
        return NULL;
    else
        return node->value;
}

int setValue(list_t* list, size_t i, void* value) {
    if (!list)
        return 1;

    node_t* node = walkList(list, i);
    if (!node)
        return 2;

    node->value = value;
    return 0;
}


int unlink(node_t* node, int free_value) {
    if (!node)
        return 1;

    node_t* next = node->next;
    node_t* prev = node->prev;

    if (next)
        next->prev = prev;

    if (prev)
        prev->next = next;

    if (free_value == 1)
        free(node->value);

    free(node);
    return 0;
}


int append(list_t* list, void* elem) {
    if (!list || !elem)
        return 1;

    node_t* new_tail = malloc(sizeof(node_t));
    if (!new_tail)
        return 2;

    new_tail->value = elem;
    if (!getHeadNode(list)) {
        setHeadNode(list, new_tail);
        list->len--; // avoid double increment
    }

    setTailNode(list, new_tail);
    return 0;
}

int appendCopy(list_t* list, void* elem, size_t size) {
    if (!list || !elem)
        return 1;

    node_t* new_tail = malloc(sizeof(node_t));
    if (!new_tail)
        return 2;

    new_tail->value = malloc(size);
    if (!new_tail->value)
        return 3;

    memcpy(new_tail->value, elem, size);

    new_tail->next = NULL;
    new_tail->prev = list->tail;

    list->tail->next = new_tail;
    list->tail = new_tail;
    list->len++;
    return 0;
}

list_t* initList(void) {
    list_t* list = malloc(sizeof(list_t));
    if (!list)
        return NULL;

    list->len = 0;
    list->head = NULL;
    list->tail = NULL;
    return list;   
}

list_t* initListFromStringArray(char** arr, size_t len) {
    list_t* list = initList();
    if(!list)
        return NULL;

    for (size_t i = 0; i < len; i++)
        append(list, arr[i]);

    return list;
}

void freeList(list_t** _list, int free_values) {
    
    if (!_list || !*_list)
        return;

    list_t* list = *_list;

    node_t* next;
    for (node_t* current = list->head; current != NULL; current = next) {
        if (free_values && current->value)
            free(current->value);

        next = current->next;
        free(current);
    }

    free(list);
    *_list = NULL;
}


#define SUPPORTED_FMTS 5
#define FMT_STRING 0
#define FMT_DECIMAL 1
#define FMT_UNSIGNED 2
#define FMT_SIZE 3
#define FMT_DOUBLE 4
#define FMT_FLOAT 5
#define FMT_UNSUPPORTED 6
void printList(const list_t* list, const char* fmt) {
    const char* separator = " [%zu] ";
    
    printf("*** Linked list at %p ***\n", list);
    if (!list)
        return;

    printf("List length: %zu\n", list->len);

    // Find appropriate format
    unsigned counter = 0;
    char* reference_fmts[] = {"%s", "%d", "%u", "%zu", "%ff", "%f", NULL};
    char* p = NULL;
    do {
        p = strstr(fmt, reference_fmts[counter]);
    } while (!p && counter++ < FMT_UNSUPPORTED);

    if (counter == FMT_UNSUPPORTED) {
        printf("Unsupported format. Supported formats are: ");
        for (unsigned i = 0; i < SUPPORTED_FMTS; i++) {
            printf("%s ", reference_fmts[i]);
        }
        return;
    }

    printf("Using %s format\n", reference_fmts[counter]);

    size_t node_num = 0;
    for (node_t* current = list->head; current != NULL; current = current->next) {
        printf(separator, node_num++);

        switch (counter) {
            case (FMT_STRING):
                printf(fmt, (char*)current->value); // Note: strings are the only ones that are not dereferenced
                break;
            case (FMT_DECIMAL):
                printf(fmt, *(int*)current->value);
                break;
            case (FMT_UNSIGNED):
                printf(fmt, *(unsigned*)current->value);
                break;
            case (FMT_SIZE):
                printf(fmt, *(size_t*)current->value);
                break;
            case (FMT_FLOAT):
                printf(fmt, *(float*)current->value);
                break;
            case (FMT_DOUBLE):
                printf(fmt, *(double*)current->value);
                break;
            default:
                // unreachable                
            
        }

        printf("\n");
    }
    printf("\n");

}


#ifdef TESTING
int main() {

    char* arr[] = {"Hello", "world", "what", "is", "up", "?"};
    size_t num_args = sizeof(arr) / sizeof(arr[0]);
    list_t* list = initListFromStringArray(arr, num_args);
    if(!list) return 1;
    printList(list, "%s");
    freeList(&list, 0);

    list_t* string_list = initList();
    append(string_list, "hello");
    append(string_list, "world");
    printList(string_list, "%s");

    list_t* num_list = initList();
    int a = 1;
    int b = 5;
    append(num_list, &a);
    append(num_list, &b);
    printList(num_list, "%d");

    list_t* unsigned_list = initList();
    unsigned ua = 128;
    unsigned ub = 259; // 1 << 32 - 1;
    append(unsigned_list, &ua);
    append(unsigned_list, &ub);
    printList(unsigned_list, "%u");

    
    list_t* float_list = initList();
    float c = 1.72;
    float d = 17.232;
    append(float_list, &c);
    append(float_list, &d);
    printList(float_list, "%f");


    list_t* double_list = initList();
    double pi = 3.14159265358;
    double e = 2.714;
    append(double_list, &pi);
    append(double_list, &e);
    printList(double_list, "%ff");


    
    freeList(&string_list, 0);
    freeList(&num_list, 0);
    freeList(&unsigned_list, 0);
    freeList(&float_list, 0);
    freeList(&double_list, 0);
    return 0;
}
#endif
