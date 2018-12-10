import csv
from random import randint, uniform, random, randrange
 
 
data_list = list()
coord_x = list()
all_values =list()
new_values=list()
new_values2=list()
 
 
# List with random values
rand_values = [random() for i in range(470)]
print (rand_values)
 
# Creating dictionary
with open('data.csv') as csvfile:
    reader = csv.DictReader(csvfile, delimiter=';')
    for row in reader:
        data_list.append(row)  # adding each of line to diccionary
        if row['x'] not in coord_x:
            coord_x.append(row['x'])
            new_values.append(row)
 
print '\nExample data_list: \n' + str(data_list[1]) + '\n'
print 'The lenght of coord_x is: ' + str(len(new_values))
print 'Total points: ' + str(len(data_list))
print '***Size new_values before adding 10 new records: \n    ' + str(len(new_values))
 
# Creating a new dictionary 10 times more
for i in range(len(new_values)):
    for j in range(9):
        empty = {}
        for elm in new_values[i].keys():
            print new_values[i].keys()
            if elm == "value":
                empty[elm] = random()
            else:
                empty[elm]=new_values[i][elm]
 
            print empty
        new_values2.append(empty)
 
print '***Size new_values after adding 10 records: \n    ' + str(len(new_values))
print 'Example new_values: \n' + str(new_values[0])
 
for el in new_values2:
    data_list.append(el)
# Creating a new csv file
with open('test_10.csv', 'wb') as f:
    writer = csv.DictWriter(f,data_list[0].keys())
    writer.writeheader()
    for line in data_list:
        writer.writerow(line)