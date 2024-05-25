
class basicBlock:
    def __init__(self, label):
        self.label = label
        self.body = []
        self.successors = [] 
        

class function:
    def __init__(self, name, body):
        self.name = name
        self.body = body
        self.blocks = []

# take llvm code and separate it into functions
def separateFunctions(text):
    functions = []
    lines = text.split("\n")
    i = 0
    while i < len(lines):
        functon = []
        if lines[i].startswith("define"):
            functon.append(lines[i].strip())
            i += 1
            while i < len(lines) and not lines[i].startswith("define"):
                functon.append(lines[i].strip())
                i += 1
            functions.append(functon)
        else:
            i += 1
    return functions

def seperateBlocks(function):
    blocks = {}
    i = 1
    while i < len(function):
        if function[i][-1] == ":":
            blocks[function[i][ ] = []

def test():
    file = open("test.ll", "r")
    text = file.read()
    functions = separateFunctions(text)
    for function in functions:
        print("\n THIS IS A FUNCTION \n\n")
        print(function)
        print("\n")

if __name__ == "__main__":
    test()
