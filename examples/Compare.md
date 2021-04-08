Comparison Examples
===================
- [Python vs Prelude](#python-vs-prelude)
- [Pandas vs Prelude](#pandas-vs-prelude)
- [NumPy vs Prelude](#numpy-vs-prelude)

Python vs Prelude
=================

Read a CSV file
---------------

**data.csv**
```csv
foo,bar
blue,small
red,medium
green,large
```

**Python**
```Python
import csv
with open('data.csv') as csv_file:
    csv_reader = csv.reader(csv_file, delimiter=',')
    for row in csv_reader:
         print(row[0])
```
**Prelude (PowerShell)**
```PowerShell
Get-Content 'data.csv' | ConvertFrom-Csv | ForEach-Object { $_.foo }
```

Read a JSON file
----------------

***data.json***
```json
{
    "PowerLevel": 9001
}
```

***Python***
```Python
import json
with open('data.json', 'r') as myfile:
    data = myfile.read()
    obj = json.loads(data)
    print(obj["PowerLevel"])
```
***Prelude***
```PowerShell
Import-Module 'Prelude'
Get-Content 'data.json' | ConvertFrom-Json | prop 'PowerLevel'
```

Pandas vs Prelude
=================

Rename column names
-------------------

**data.csv**
```csv
foo,bar
blue,small
red,medium
green,large
```

**Pandas**
```python
import pandas as pd
data = pd.read_csv("data.csv")
col_map = {
    "foo": "color",
    "bar": "size"
}
data = data.rename(columns=col_map)
```
**Prelude**
```PowerShell
Import-Module 'Prelude'
$Data = Get-Content 'data.csv' | ConvertFrom-Csv
$Lookup = @{
    color = 'foo'
    size = 'bar'
}
$Data = $Data | transform $Lookup
```

NumPy vs. Prelude
=================

Create an matrix from a range of numbers
---------------------------------------

**NumPy**
```python
import numpy as np
ndArray = np.arange(9).reshape(3, 3)
a = np.map(ndArray)
```
**Prelude**
```PowerShell
Import-Module 'Prelude'
$A = 1..9 | matrix 3,3
```

Calculate dot product of two matrices
-------------------------------------

**NumPy**
```python
import numpy as np
x = np.array([[1, 2], [3, 4]])
y = np.array([[10, 20], [30, 40]])
product = np.dot(x, y)
```
**Prelude**
```PowerShell
Import-Module 'Prelude'
$X = 1, 2, 3, 4 | matrix
$Y = 10, 20, 30, 40 | matrix
$Product = $X * $Y
```

Calculate matrix determinant or inverse
---------------------------------------

**NumPy**
```python
import numpy as np
x = np.array([[4, 8], [7, 9]])
determinant = np.linalg.det(x)
inverse = np.linalg.inv(x)
```
**Prelude**
```PowerShell
Import-Module 'Prelude'
$X = 4, 8, 7, 9 | matrix
$Determinant = $X.Det()
$Inverse = $X.Inverse()
```