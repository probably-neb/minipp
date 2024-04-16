import random

class Scope:
    def __init__(self, parent=None):
        self.variables = {}  # Maps variable names to their types
        self.parent = parent

    def add_variable(self, name, var_type):
        self.variables[name] = var_type

    def find_variable(self, name):
        if name in self.variables:
            return self.variables[name]
        elif self.parent:
            return self.parent.find_variable(name)
        return None

    def get_random_variable(self, var_type=None):
        if var_type:
            candidates = {name: type for name, type in self.variables.items() if type == var_type}
        else:
            candidates = self.variables
        return random.choice(list(candidates.keys())) if candidates else None

    def get_all_variables(self):
        if self.parent:
            return {**self.parent.get_all_variables(), **self.variables}
        return self.variables

class MiniLangGenerator:
    def __init__(self):
        self.global_scope = Scope()
        self.structures = {}  # name to fields mapping

    def generate_identifier(self, scope, prefix='var'):
        existing = scope.get_all_variables().keys()
        while True:
            identifier = f"{prefix}{random.randint(0, 1000)}"
            if identifier not in existing:
                return identifier

    def generate_type(self, allow_structs=True):
        basic_types = ["int", "bool"]
        struct_types = list(self.structures.keys()) if allow_structs else []
        return random.choice(basic_types + struct_types)

    def generate_declaration(self, scope, var_type=None):
        var_type = var_type or self.generate_type()
        var_name = self.generate_identifier(scope)
        scope.add_variable(var_name, var_type)
        return f"{var_type} {var_name};"

    def generate_expression(self, var_type, scope):
        if var_type in ["int", "bool"]:
            var_name = scope.get_random_variable(var_type)
            if var_name:
                return var_name
            return str(random.randint(0, 100)) if var_type == "int" else random.choice(["true", "false"])
        else:
            return "null"

    def generate_statement(self, scope):
        stmt_type = random.choice(["assignment", "print", "conditional", "loop"])
        if stmt_type == "assignment":
            var_name = scope.get_random_variable()
            if not var_name:
                return ""
            expr = self.generate_expression(scope.find_variable(var_name), scope)
            return f"{var_name} = {expr};"
        elif stmt_type == "print":
            var_name = scope.get_random_variable("int")  # Assuming print only for int types
            if not var_name:
                return ""
            return f"print {var_name};"
        # Implement other types as per Mini language spec

    def generate_function(self, name="main", return_type="int", num_statements=3):
        func_scope = Scope(self.global_scope)
        func_body = f"fun {name}() {return_type} " + "{\n"
        
        # Generate function-local declarations
        for _ in range(random.randint(1, 3)):  # Random number of local declarations
            decl = self.generate_declaration(func_scope)
            func_body += f"    {decl}\n"

        # Generate function body statements
        for _ in range(num_statements):
            stmt = self.generate_statement(func_scope)
            if stmt:
                func_body += f"    {stmt}\n"

        func_body += "    return 0;\n" if return_type == "int" else ""
        func_body += "}\n"
        return func_body

    def generate_program(self, num_functions=1):
        program = ""

        # Global declarations
        for _ in range(random.randint(1, 5)):  # Random number of global declarations
            decl = self.generate_declaration(self.global_scope)
            program += f"{decl}\n"

        # Functions
        for i in range(num_functions):
            func_name = self.generate_identifier(self.global_scope, prefix='func') if i > 0 else "main"
            program += self.generate_function(func_name)

        return program

# Create an instance of the code generator
generator = MiniLangGenerator()
# Generate a random Mini language program
mini_program = generator.generate_program()

print(mini_program)
