# -*- coding: utf-8 -*-
"""
Created on Mon Dec 27 15:22:30 2021

@author: dan.nguyen
"""

# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
import numpy as np
import pandas as pd


import matplotlib.pyplot as plt


import pyodbc 

conn = pyodbc.connect('Driver={SQL Server};'
                      'Server=DB215;'
                      'Database=bodb_Account;'
                      'Trusted_Connection=yes;')


# conn = pyodbc.connect('Driver={SQL Server};'
#                       'Server=DBDW2;'
#                       'Database=bodb_Account;'
#                       'UID=vnteam;'
#                       'PWD=xxxx;'
#                       'Trusted_Connection=no;')



#cursor = conn.cursor()
#cursor.execute('SELECT ID, statusname FROM DimLiveStatus')

# for i in cursor:
#    print(i)


#df = pd.DataFrame(cursor.fetchall(), columns = ['ID', 'statusname'  ])
#print (df)


data = pd.read_sql('SELECT ID, statusname FROM DimLiveStatus', conn)
data