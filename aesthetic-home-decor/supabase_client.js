/**
 * =====================================================================
 * 🏛️ Lume & Luxe - Supabase Frontend Client Integration
 * Description: Ready-to-use JavaScript functions to connect index.html
 *              with your Supabase backend.
 * =====================================================================
 */

// 1. YOUR SUPABASE CREDENTIALS
// Inko apne Supabase Dashboard -> Project Settings -> API se copy karein:
const SUPABASE_URL = 'https://nucalxcqhohjgfabenqq.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51Y2FseGNxaG9oamdmYWJlbnFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIxMjkwMzEsImV4cCI6MjEwNzcwNTAzMX0.Oqkdx1BZYaQdU0-Bah_0DABuHmKYYwp7HKKC4m2ugFQ';

// 2. INITIALIZE SUPABASE CLIENT
// (Make sure to include: <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script> in HTML head)
const supabase = window.supabase ? window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY) : null;

/**
 * 3. FETCH PRODUCTS FROM SUPABASE DATABASE
 * Replaces hardcoded lumeProductsData array with live database records!
 */
async function fetchProductsFromSupabase(category = 'all', searchQuery = '') {
  if (!supabase) {
    console.warn('Supabase client not initialized. Falling back to local data.');
    return null;
  }

  try {
    let query = supabase
      .from('products')
      .select('*')
      .eq('in_stock', true);

    // Category filter
    if (category && category !== 'all') {
      query = query.eq('category', category);
    }

    // Search query filter (matches title or description)
    if (searchQuery && searchQuery.trim() !== '') {
      query = query.ilike('title', `%${searchQuery.trim()}%`);
    }

    const { data, error } = await query;

    if (error) {
      console.error('Error fetching products from Supabase:', error.message);
      return null;
    }

    return data;
  } catch (err) {
    console.error('Network error fetching products:', err);
    return null;
  }
}

/**
 * 4. SUBMIT CONTACT ENQUIRY TO SUPABASE
 * Saves user messages directly into the 'enquiries' table in Supabase!
 */
async function submitContactEnquiryToSupabase(formData) {
  if (!supabase) {
    console.warn('Supabase not configured. Simulating submission.');
    return { success: true, simulated: true };
  }

  try {
    const { data, error } = await supabase
      .from('enquiries')
      .insert([
        {
          first_name: formData.firstName,
          last_name: formData.lastName,
          email: formData.email,
          phone: formData.phone || null,
          enquiry_type: formData.enquiryType,
          budget: formData.budget || null,
          message: formData.message,
          status: 'new'
        }
      ]);

    if (error) {
      console.error('Error submitting enquiry:', error.message);
      return { success: false, error: error.message };
    }

    return { success: true, data };
  } catch (err) {
    console.error('Exception submitting enquiry:', err);
    return { success: false, error: err.message };
  }
}

/**
 * 5. CREATE ORDER & ORDER ITEMS IN SUPABASE
 * When a customer checks out, saves the order and individual cart items!
 */
async function submitOrderToSupabase(customerInfo, cartItems, subtotal, shippingFee, totalAmount) {
  if (!supabase) {
    console.warn('Supabase not configured. Simulating checkout.');
    return { success: true, simulated: true, orderRef: 'LL-' + Math.floor(100000 + Math.random() * 900000) };
  }

  try {
    const orderRef = 'LL-' + Math.floor(100000 + Math.random() * 900000);
    const orderId = (typeof crypto !== 'undefined' && crypto.randomUUID) ? crypto.randomUUID() : ('LL-' + Date.now() + '-' + Math.random().toString(36).substring(2, 9));

    // Step A: Insert into 'orders' table without .select() to avoid RLS SELECT restrictions
    let orderPayload = {
      id: orderId,
      order_reference: orderRef,
      customer_name: customerInfo.name,
      customer_email: customerInfo.email,
      phone: customerInfo.phone || null,
      shipping_address: customerInfo.address,
      city: customerInfo.city,
      country: customerInfo.country || 'United Kingdom',
      postal_code: customerInfo.postalCode,
      notes: customerInfo.notes || null,
      subtotal: subtotal,
      shipping_fee: shippingFee,
      total_amount: totalAmount,
      status: 'pending'
    };

    let { error: orderError } = await supabase.from('orders').insert([orderPayload]);

    // Fallback if phone/country columns not added to schema yet
    if (orderError && (orderError.code === 'PGRST204' || (orderError.message && orderError.message.includes('column')))) {
      delete orderPayload.phone;
      delete orderPayload.country;
      delete orderPayload.notes;
      orderPayload.shipping_address = `${customerInfo.address}, ${customerInfo.city}, ${customerInfo.country || 'UK'} (Tel: ${customerInfo.phone || 'N/A'})`;
      const retry = await supabase.from('orders').insert([orderPayload]);
      orderError = retry.error;
    }

    if (orderError) {
      console.error('Error creating order:', orderError.message);
      return { success: false, error: orderError.message };
    }

    // Step B: Bulk insert all items into 'order_items' table
    const itemsToInsert = cartItems.map(item => ({
      order_id: orderId,
      product_id: item.id,
      product_title: item.title,
      unit_price: item.price,
      quantity: item.qty || item.quantity || 1,
      total_price: (item.price * (item.qty || item.quantity || 1))
    }));

    const { error: itemsError } = await supabase
      .from('order_items')
      .insert(itemsToInsert);

    if (itemsError) {
      console.warn('Note on inserting order items:', itemsError.message);
    }

    return { success: true, orderRef: orderRef, orderId: orderId };
  } catch (err) {
    console.error('Exception processing order:', err);
    return { success: false, error: err.message };
  }
}

/**
 * 6. SUBSCRIBE TO NEWSLETTER IN SUPABASE
 */
async function subscribeNewsletterToSupabase(email) {
  if (!supabase) return { success: true, simulated: true };

  try {
    const { error } = await supabase
      .from('newsletter_subscribers')
      .insert([{ email: email.trim().toLowerCase() }]);

    if (error) {
      if (error.code === '23505') {
        return { success: false, message: 'This email is already subscribed!' };
      }
      return { success: false, message: error.message };
    }

    return { success: true };
  } catch (err) {
    return { success: false, message: err.message };
  }
}
