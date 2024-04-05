import sys
import random
from words import ADVERBS, ADJECTIVES, ANIMALS

DEFAULT_COMPLEXITY = 1000

INDENT = ' ' * 4

CREATED_TYPES = {
    'bool',
    'int'
}

class _types:
    created = {'bool': 0, 'int': 0}

    def save(self, ty):
        self.created[ty] = 0
    
    def exists(self, ty):
        return ty in self.created

    def set_depth(self, ty, depth):
        assert ty in self.created
        self.created[ty] = depth

Types = _types()

def main():
    args = sys.argv[1:]
    complexity = DEFAULT_COMPLEXITY
    if len(args) > 0:
        complexity = int(args[0])
    num_structs = get_num_structs(complexity)
    for _ in range(num_structs):
        gen_struct(complexity)

def write(*args):
    print(*args, end='')

def get_num_structs(complexity):
    return complexity // 100

def get_num_struct_fields(complexity):
    return random.randint(1, complexity // 100)

def gen_struct(complexity):
    struct_name = gen_struct_name()
    write('struct', struct_name, '{\n')
    num_fields = get_num_struct_fields(complexity)
    types = rand_types_with_depths(num_fields)
    max_depth = max(t[0] for t in types)
    Types.set_depth(struct_name, max_depth)
    for _ in range(num_fields):
        ty = rand_type()
        name = field_type_to_name(ty)
        write(INDENT, ty, name + ';\n')
    write('};\n\n')

def rand_struct_field_names(complexity):
    num_fields = get_num_struct_fields(complexity)
    num_adj = random.randint(0, num_fields)
    num_adv = random.randint(0, num_fields - num_adj)
    num_animals = num_fields - num_adj - num_adv

    assert num_adj + num_adv + num_animals == num_fields

    return random.sample(ADJECTIVES, num_adj) + random.sample(ADVERBS, num_adv) + random.sample(ANIMALS, num_animals)

def field_type_to_name(field_type):
    if field_type == 'bool':
        return 'is_' + gen_var_name()
    if field_type == 'int':
        return 'num_' + gen_var_name()

    assert field_type.startswith('struct ')
    # remove 'struct ' and de-titlecase it
    return field_type[7].lower() + field_type[7:]

def rand_type():
    return random.choice(Types.created.keys())

def rand_types_with_depths(k: int):
    random.choices(Types.created.items(), k=k)

def gen_var_name():
    return random.choice(random.choice([ADVERBS, ADJECTIVES, ANIMALS]))

def gen_struct_name():
    struct_name = random.choice(ADVERBS).capitalize() + random.choice(ADJECTIVES).capitalize() + random.choice(ANIMALS).capitalize()
    if Types.exists(struct_name):
        return gen_struct_name()
    Types.save(struct_name)
    return struct_name

if __name__ == "__main__":
    main()

