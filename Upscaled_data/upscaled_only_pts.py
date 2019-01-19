import shapefile
import csv
from random import uniform, random, choice
from string import ascii_uppercase, ascii_lowercase
from time import time


initial_time = time()
#-----------------------------------------------------------------------------
#----------------------------      Functions      ----------------------------
def polygon_coord_from_shp(file):
    """ Reads shapefile and extracts the coordinates of the polygon
        - Uses first feature
        - file: shapefile with path"""
    shape = shapefile.Reader(file)
    # first feature of the shapefile
    feature = shape.shapeRecords()[0]
    first = feature.shape.__geo_interface__  # GeoJSON format
    polygon = list(first['coordinates'][0])
    return polygon

def point_in_polygon(x, y, polygon):
    """ Check if a point is inside a polygon
        - x,y - Coordinates of the point
        - polygon - List of the vertices of the polygon [(x1, x2), (x2, y2), ..., (xn, yn)]"""
    i = 0
    j = len(polygon) - 1
    res = False
    for i in range(len(polygon)):
        if (polygon[i][1] < y and polygon[j][1] >= y) \
                or (polygon[j][1] < y and polygon[i][1] >= y):
            if polygon[i][0] + (y - polygon[i][1]) / (polygon[j][1] - polygon[i][1]) * (
                    polygon[j][0] - polygon[i][0]) < x:
                res = not res
        j = i
    return res
#-----------------------------------------------------------------------------
# Empty lists and others variables
all_data_list, date_list, city_list = [], [],  []
coord_list, coord_list2, coord_list3 = [], [], []
new_list_city, new_list_x, new_list_y, new_list_z = [], [], [], []
x_min, y_min, z_min = 99999, 99999, 99999
x_max, y_max, z_max = -99999, -99999, -99999
cont=0

""" Times to upscale data: """
t = 1000
print('Times to upscale is: ' + str(t))

""" Open the original file from \home\user\PostRep\input
	Is delimited by coma (,). The header has to be added manually. 
	 - Format for header: 
	id,city,x,y,z,date,time,value 
"""

#f = open(" \home\user\PostRep\input\data.csv", "r")
print('Openning the files..')
f = open("data.csv", "r")
reader = csv.DictReader(f, delimiter=',')

'''Creating a new csv file:
    That file is to test upscaled data. 
    It will be introduce as relation table station_info in the DataBase.'''
f2 = open('new_station_info_'+str(t)+'.csv', 'wb')
# The names of resulting columuns for upscaled data
csv_columns = ['id','city','x','y','z']
writer = csv.DictWriter(f2,fieldnames=csv_columns)
writer.writeheader()

print('Creating lists...')

for row in reader:
    # Creating a new list with: coord x, coord y, coord z and city
    if row['x']+','+row['y']+','+row['z']+',' + row['city'] not in coord_list:
        cont+=1
        coord_list.append(row['x']+','+row['y']+','+row['z']+','+row['city'])
        coord_list2.append(row['x'] + ',' + row['y'])
        # Adding lines from original data
        data = {'id': cont, 'city': row['city'], 'x': row['x'], 'y': row['y'], 'z': row['z']}
        writer.writerow(data)

        # Defining max and min for new coordinates
        if x_min >= float(row['x']): x_min = float(row['x'])
        if x_max <= float(row['x']): x_max = float(row['x'])
        if y_min >= float(row['y']): y_min = float(row['y'])
        if y_max <= float(row['y']): y_max = float(row['y'])
        if z_min >= float(row['z']): z_min = float(row['z'])
        if z_max <= float(row['z']): z_max = float(row['z'])

""" Since the original bourder of Germany  has too much borders to check, it has been simplified."""
file2 = "C:\Users\Nastyuja\Desktop\OpenSource\python\germany2.shp"
print('Opening shp file..')
polygon = polygon_coord_from_shp(file2) # Creating dictionary from shapefile

# Creating new random points coordinates and City's names:
print('Creating a new coordinates...')
cont2=0
times = t * len(coord_list2)
while cont2<times:
    x, y = uniform(x_min, x_max), uniform(y_min, y_max)
    # Check if new created point is inside of the boundary and the point is already exists
    if point_in_polygon(x, y, polygon) == True and ["'" + str(x) + "," + str(y) + "'"] not in coord_list2 and [x,y] not in coord_list3:
        coord_list3.append([x,y])
        cont2 += 1
        line = {'city': choice(ascii_uppercase) + choice(ascii_lowercase) + choice(ascii_lowercase) + choice(ascii_lowercase) + choice(ascii_lowercase),
                'y': "{0:.3f}".format(y),
                'x': "{0:.3f}".format(x),
                'z': "{0:.3f}".format(uniform(z_min, z_max)),
                'id': len(coord_list) + cont2}
        writer.writerow(line)
# Close the csv files
print len(coord_list3)
f.close()
f2.close()
print ('The process is finished.')
final_time = time()
execution_time = final_time - initial_time
print ('The execution time was: '+ str(execution_time) + ' seconds.')  # In seconds

