Comparison Examples
===================
- [Pandas vs Prelude](#pandas-vs-prelude)
- [NumPy vs Prelude](#numpy-vs-prelude)

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
Import-Module Prelude
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
Import-Module Prelude
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
Import-Module Prelude
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
Import-Module Prelude
$X = 4, 8, 7, 9 | matrix
$Determinant = $X.Det()
$Inverse = $X.Inverse()
```