Comparison Examples
===================
- [Python vs Prelude](#python-vs-prelude)
- [Pandas vs Prelude](#pandas-vs-prelude)
- [NumPy vs Prelude](#numpy-vs-prelude)
- [JavaScript vs Prelude](#javascript-vs-prelude)

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

Simple linear regression (with [SciKit-Learn](https://scikit-learn.org/stable/index.html))
--------------------------------------------

**NumPy** and **SciKit-Learn**
```python
import numpy as np
from sklearn.linear_model import LinearRegression
x = np.array([5, 15, 25, 35, 45, 55]).reshape((-1, 1))
y = np.array([5, 20, 14, 32, 22, 38])
model = LinearRegression().fit(x, y)
print('Intercept:', model.intercept_)
print('Slope:', model.coef_)
```
**Prelude**
```PowerShell
Import-Module 'Prelude'
$X0 = matrix -Unit 6,1
$X1 = 5, 15, 25, 35, 45, 55 | matrix 6,1
$X = $X0.Augment($X1)
$Y = 5, 20, 14, 32, 22, 38 | matrix 6,1
$B = ($X.Transpose() * $X).Inverse() * ($X.Transpose() * $Y)
"Intercept: $($B[0].Real)" | Write-Color -Green
"Slope: $($B[1].Real)" | Write-Color -Green
```

JavaScript vs Prelude
=====================

Find the length of the longest word in a list
---------------------------------------------

**JavaScript**
```js
const result = Math.max(...(['always', 'look', 'on', 'the', 'bright', 'side', 'of', 'life'].map(el => el.length)));
console.log(result);
```
**Prelude**
```PowerShell
Import-Module 'Prelude'
'always', 'look', 'on', 'the', 'bright', 'side', 'of', 'life' | prop Length | max
```

Partition an array
------------------

**JavaScript**
```js
const partition = (arr, predicate) => arr.reduce((acc, i) => (acc[predicate(i) ? 0 : 1].push(i), acc), [[], []]);
const isEven = n => n % 2 === 0
const result = partition([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], isEven);
console.log(result);
```
**Prelude**
```PowerShell
Import-Module 'Prelude'
$IsEven = { Param($X) $X % 2 -eq 0 }
1..10 | partition $IsEven
```

Chunk an array into smaller arrays
----------------------------------

**JavaScript**
```js
const chunk = (arr, size) => arr.reduce((acc, e, i) => (i % size ? acc[acc.length - 1].push(e) : acc.push([e]), acc), []);
const result = chunk([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 3);
console.log(result);
```
**Prelude**
```PowerShell
Import-Module 'Prelude'
1..10 | chunk -s 3
```

Zip two arrays into a single array
----------------------------------

**JavaScript**
```js
const zip = (...arr) => Array.from({length: Math.max(...arr.map(a => a.length))}, (_, i) => arr.map(a => a[i]));
const result = zip(['a', 'b', 'c', 'd', 'e'], [1, 2, 3, 4, 5]);
console.log(result);
```
**Prelude**
```PowerShell
Import-Module 'Prelude'
@('a', 'b', 'c', 'd', 'e'), (1..5) | zip
```

Unzip an array into two arrays
------------------------------

**JavaScript**
```js
const unzip = arr => arr.reduce((acc, c) => (c.forEach((v, i) => acc[i].push(v)), acc), Array.from({length: Math.max(...arr.map(a => a.length))}, (_) => []));
const result = unzip([['a', 1], ['b', 2], ['c', 3], ['d', 4], ['e', 5]]);
console.log(result);
```
**Prelude**
```PowerShell
Import-Module 'Prelude'
@('a', 1), @('b', 2), @('c', 3), @('d', 4), @('e', 5) | unzip
```