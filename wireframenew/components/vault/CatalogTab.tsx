import { useState } from 'react';
import { Package, Search, Plus, Filter } from 'lucide-react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';

interface Product {
  id: string;
  name: string;
  sku: string;
  price: number;
  category: string;
  thumbnail?: string;
}

export function CatalogTab() {
  const [selectedCategory, setSelectedCategory] = useState('All');

  const mockProducts: Product[] = [
    {
      id: '1',
      name: 'Asphalt Shingles - Premium',
      sku: 'ASH-001',
      price: 89.99,
      category: 'Roofing'
    },
    {
      id: '2',
      name: 'Aluminum Gutters 6"',
      sku: 'GUT-006',
      price: 12.50,
      category: 'Gutters'
    },
    {
      id: '3',
      name: 'Roofing Nails 1.5"',
      sku: 'NAI-150',
      price: 45.00,
      category: 'Hardware'
    },
    {
      id: '4',
      name: 'Waterproof Membrane',
      sku: 'MEM-001',
      price: 125.00,
      category: 'Roofing'
    },
    {
      id: '5',
      name: 'Ridge Vent System',
      sku: 'RID-001',
      price: 28.75,
      category: 'Ventilation'
    },
    {
      id: '6',
      name: 'Flashing Kit - Aluminum',
      sku: 'FLA-ALU',
      price: 34.99,
      category: 'Hardware'
    }
  ];

  const categories = ['All', 'Roofing', 'Gutters', 'Hardware', 'Ventilation', 'Insulation'];

  const filteredProducts = selectedCategory === 'All' 
    ? mockProducts 
    : mockProducts.filter(product => product.category === selectedCategory);

  return (
    <div className="flex flex-col h-full">
      {/* Search and Add */}
      <div className="p-4 border-b border-stroke bg-surface">
        <div className="flex space-x-2 mb-4">
          <div className="flex-1 relative">
            <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="Search products..."
              className="w-full pl-10 pr-4 py-2 border border-stroke rounded-lg bg-background text-sm"
            />
          </div>
          <Button size="sm" className="px-3">
            <Plus size={16} className="mr-2" />
            Add
          </Button>
        </div>

        {/* Category Filters */}
        <div className="flex space-x-2 overflow-x-auto scrollable">
          {categories.map((category) => (
            <button
              key={category}
              onClick={() => setSelectedCategory(category)}
              className={`flex-shrink-0 px-3 py-1.5 rounded-full text-xs transition-colors ${
                selectedCategory === category
                  ? 'bg-primary text-primary-foreground'
                  : 'bg-muted text-muted-foreground hover:bg-muted/80'
              }`}
            >
              {category}
            </button>
          ))}
        </div>
      </div>

      {/* Product List */}
      <div className="flex-1 overflow-y-auto scrollable">
        <div className="p-4 space-y-3">
          {filteredProducts.map((product) => (
            <div
              key={product.id}
              className="flex items-center space-x-3 p-3 bg-card rounded-lg border border-stroke hover:bg-accent/50 transition-colors"
            >
              <div 
                className="bg-gray-100 rounded-lg flex items-center justify-center flex-shrink-0"
                style={{ width: '56px', height: '56px' }}
              >
                <Package size={24} className="text-muted-foreground" />
              </div>
              
              <div className="flex-1 min-w-0">
                <div className="font-medium text-sm truncate">
                  {product.name}
                </div>
                <div className="text-xs text-muted-foreground">
                  SKU: {product.sku}
                </div>
                <Badge variant="secondary" className="text-xs mt-1">
                  {product.category}
                </Badge>
              </div>
              
              <div className="text-right">
                <div className="font-semibold text-sm">
                  ${product.price}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}