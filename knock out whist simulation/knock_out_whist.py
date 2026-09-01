import random

class Card:
    def __init__(self, rank, suit):
        self.rank = rank
        self.suit = suit

    def __repr__(self):
        return f'{self.rank} of {self.suit}'

suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades']
ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']

deck = [Card(rank, suit) for suit in suits for rank in ranks]

number_of_runs = 5000000
number_of_wins_for_trump = 0
for _ in range(number_of_runs):
    players = random.sample(deck, 4)
    #print(players)

    for i in range(1,4):
        #players[0] is trump
        if players[0].suit == players[i].suit:
            if players[0].rank < players[i].rank:
                #print("trump lost")
                break
    else:
        # triggers when loop ends without break
        number_of_wins_for_trump += 1
        #print("trump won")

print(f"Probability of winning: {number_of_wins_for_trump / number_of_runs}")