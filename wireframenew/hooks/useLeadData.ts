import { useState, useEffect } from 'react';

// Shared customer data - used by both leads and kanban views
export interface Customer {
  id: string;
  name: string;
  phone: string;
  location: string;
  address?: string;
  email?: string;
  avatar?: string;
}

export interface Lead {
  id: string;
  name: string;
  phone: string;
  email: string;
  address: string;
  status: 'hot' | 'warm' | 'cold' | 'dormant';
  estimatedValue?: number;
  source: string;
  lastContact: string;
  dateCreated: Date;
  notes?: string;
}

export const sharedCustomers: Customer[] = [
  {
    id: '1',
    name: 'Alice Thompson',
    phone: '(555) 123-4567',
    location: 'Austin, TX 78701',
    address: '123 Oak Street, Austin, TX 78701',
    email: 'alice.thompson@email.com'
  },
  {
    id: '2', 
    name: 'Bob Wilson',
    phone: '(555) 987-6543',
    location: 'Dallas, TX 75201',
    address: '456 Elm Avenue, Dallas, TX 75201',
    email: 'bob.wilson@email.com'
  },
  {
    id: '3',
    name: 'Carol Davis', 
    phone: '(555) 456-7890',
    location: 'Houston, TX 77001',
    address: '789 Pine Road, Houston, TX 77001',
    email: 'carol.davis@email.com'
  },
  {
    id: '4',
    name: 'David Brown',
    phone: '(555) 321-0987',
    location: 'San Antonio, TX 78201',
    address: '321 Maple Drive, San Antonio, TX 78201',
    email: 'david.brown@email.com'
  },
  {
    id: '5',
    name: 'Emma Johnson',
    phone: '(555) 234-5678',
    location: 'Austin, TX 78702',
    address: '654 Cedar Lane, Austin, TX 78702',
    email: 'emma.johnson@email.com'
  },
  {
    id: '6',
    name: 'Frank Miller',
    phone: '(555) 345-6789',
    location: 'Plano, TX 75023',
    address: '987 Birch Street, Plano, TX 75023',
    email: 'frank.miller@email.com'
  },
  {
    id: '7',
    name: 'Grace Lee',
    phone: '(555) 456-1234',
    location: 'Fort Worth, TX 76101',
    address: '147 Walnut Avenue, Fort Worth, TX 76101',
    email: 'grace.lee@email.com'
  },
  {
    id: '8',
    name: 'Henry Clark',
    phone: '(555) 567-8901',
    location: 'Arlington, TX 76001',
    address: '258 Chestnut Road, Arlington, TX 76001',
    email: 'henry.clark@email.com'
  }
];

// Mock leads data
const mockLeads: Lead[] = [
  {
    id: '1',
    name: 'Alice Thompson',
    phone: '(555) 123-4567',
    email: 'alice.thompson@email.com',
    address: '123 Oak Street, Austin, TX 78701',
    status: 'hot',
    estimatedValue: 2500,
    source: 'Website',
    lastContact: '2 days ago',
    dateCreated: new Date(2024, 5, 10),
    notes: 'Interested in roof repair'
  },
  {
    id: '2',
    name: 'Bob Wilson',
    phone: '(555) 987-6543',
    email: 'bob.wilson@email.com',
    address: '456 Elm Avenue, Dallas, TX 75201',
    status: 'warm',
    estimatedValue: 5800,
    source: 'Referral',
    lastContact: '5 days ago',
    dateCreated: new Date(2024, 5, 5),
    notes: 'Full roof replacement needed'
  },
  {
    id: '3',
    name: 'Carol Davis',
    phone: '(555) 456-7890',
    email: 'carol.davis@email.com',
    address: '789 Pine Road, Houston, TX 77001',
    status: 'hot',
    estimatedValue: 3200,
    source: 'Google Ads',
    lastContact: '1 day ago',
    dateCreated: new Date(2024, 2, 10),
    notes: 'Gutter work needed'
  },
  {
    id: '4',
    name: 'David Brown',
    phone: '(555) 321-0987',
    email: 'david.brown@email.com',
    address: '321 Maple Drive, San Antonio, TX 78201',
    status: 'warm',
    estimatedValue: 12000,
    source: 'Facebook',
    lastContact: 'Today',
    dateCreated: new Date(2024, 5, 11),
    notes: 'Commercial property'
  },
  {
    id: '5',
    name: 'Emma Johnson',
    phone: '(555) 234-5678',
    email: 'emma.johnson@email.com',
    address: '654 Cedar Lane, Austin, TX 78702',
    status: 'cold',
    estimatedValue: 1800,
    source: 'Cold Call',
    lastContact: '8 days ago',
    dateCreated: new Date(2024, 3, 8),
    notes: 'Small repair needed'
  },
  {
    id: '6',
    name: 'Frank Miller',
    phone: '(555) 345-6789',
    email: 'frank.miller@email.com',
    address: '987 Birch Street, Plano, TX 75023',
    status: 'dormant',
    estimatedValue: 15000,
    source: 'Website',
    lastContact: '12 days ago',
    dateCreated: new Date(2023, 11, 10),
    notes: 'Large project, premium client'
  },
  {
    id: '7',
    name: 'Grace Lee',
    phone: '(555) 456-1234',
    email: 'grace.lee@email.com',
    address: '147 Walnut Avenue, Fort Worth, TX 76101',
    status: 'warm',
    estimatedValue: 4200,
    source: 'Referral',
    lastContact: '3 days ago',
    dateCreated: new Date(2024, 4, 15),
    notes: 'Storm damage repair'
  },
  {
    id: '8',
    name: 'Henry Clark',
    phone: '(555) 567-8901',
    email: 'henry.clark@email.com',
    address: '258 Chestnut Road, Arlington, TX 76001',
    status: 'cold',
    estimatedValue: 2800,
    source: 'Yellow Pages',
    lastContact: '6 days ago',
    dateCreated: new Date(2024, 4, 20),
    notes: 'Maintenance work'
  }
];

export function getCustomerById(id: string): Customer | undefined {
  return sharedCustomers.find(customer => customer.id === id);
}

export function useLeadData() {
  const [leads, setLeads] = useState<Lead[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Simulate API call
    const timer = setTimeout(() => {
      setLeads(mockLeads);
      setLoading(false);
    }, 500);

    return () => clearTimeout(timer);
  }, []);

  return {
    leads,
    loading,
    setLeads
  };
}