def geq(a, b):
    return a >= b

def logical_mess(a, b, c):
    if a is None or b is None or c is None:
        return -1
    if a == b == c:
        return 2
    if a == b or a == c or b == c:
        return 1
    if c == 10 and a != 5:
        return 3
    if c == 10 and a == 5:
        return 4
    if c > 10 and a > b:
        return 4
    return 6

class Adventurer:
    
    def __init__(self, name: str, gold: int):
        self.name = name
        self.gold = gold if gold >= 0 else 0
        self.inventory = []

    def lose_gold(self, amount: int):
        if self.gold - amount < 0:
            self.gold = 0
            return False
        else:
            self.gold -= amount
            return True

    def win_gold(self, amount: int):
        self.gold += amount

    def add_inventory(self, item: str):
        self.inventory.append(item)

    def remove_inventory(self, item: str):
        if item in self.inventory:
            self.inventory.remove(item)
            return True


