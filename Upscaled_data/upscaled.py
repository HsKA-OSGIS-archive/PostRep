import csv
from random import uniform, random, choice
from string import ascii_uppercase, ascii_lowercase
from time import time

initial_time = time()
all_data_list, values_list, date_list = [], [], []
city_list= []
new_list_city, new_list_x, new_list_y, new_list_z = [], [], [], []

times = 100000

x_min, y_min, z_min = 99999, 99999, 99999
x_max, y_max, z_max = -99999, -99999, -99999

f = open('data.csv', 'r')
reader = csv.DictReader(f, delimiter=';')

# The limits of the coordinates
for row in reader:
    all_data_list.append(row)
    if row['date'] not in date_list:
        date_list.append(row['date'])
    # Max and min
    if x_min >= float(row['x']):
        x_min = float(row['x'])
    if x_max <= float(row['x']):
        x_max = float(row['x'])
    if y_min >= float(row['y']):
        y_min = float(row['y'])
    if y_max <= float(row['y']):
        y_max = float(row['y'])
    if z_min >= float(row['z']):
        z_min = float(row['z'])
    if z_max <= float(row['z']):
        z_max = float(row['z'])

a=len(all_data_list)
print('The size of original data is: ' + str(a))
for i in range(times):
    new_list_city.append(choice(ascii_uppercase) +
                         choice(ascii_lowercase) +
                         choice(ascii_lowercase) +
                         choice(ascii_lowercase) +
                         choice(ascii_lowercase))
    new_list_x.append(uniform(x_min, x_max))
    new_list_y.append(uniform(y_min, y_max))
    new_list_z.append(uniform(z_min, z_max))

print('The list in all_data_list example:\n'+str(all_data_list[0]))
# Rondom values for measurements:
    # the size of new measurements
num_total_new_points=len(date_list)*times
#new_list_value = [random() for j in range(num_total_new_points)]

cont2=len(all_data_list)-1
# Creating a new dictionary with all values

with open('new_test_'+str(times)+'.csv', 'wb') as f2:
    writer = csv.DictWriter(f2,all_data_list[0].keys())
    writer.writeheader()

    for row in all_data_list:
        writer.writerow(row)

    for k in range(times):
        for m in range(len(date_list)):
            cont2 += 1
            line = {'city': new_list_city[k],
                             'value': "{0:.12f}".format(random()),
                              'y': "{0:.3f}".format(new_list_y[k]),
                              'date': date_list[m],
                              'x': "{0:.3f}".format(new_list_x[k]),
                              'z': "{0:.3f}".format(new_list_z[k]),
                              'id': cont2}

            writer.writerow(line)
f.close()
f2.close()
print ('The process is finished.')
# To see time
final_time = time()
execution_time = final_time - initial_time
print ('The execution time was: '+ str(execution_time) + ' seconds.')  # En segundos