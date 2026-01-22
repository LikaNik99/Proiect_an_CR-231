import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { passwordAPI, authAPI } from '../services/api';
import { 
  FiPlus, FiEdit2, FiTrash2, FiEye, FiEyeOff, FiCopy, FiStar, 
  FiLogOut, FiSearch, FiLock, FiGlobe, FiFolder, FiMenu, FiX,
  FiList, FiChevronLeft, FiChevronRight, FiUser, FiSettings
} from 'react-icons/fi';
import './Dashboard.css';

const Dashboard = () => {
  const [passwords, setPasswords] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingPassword, setEditingPassword] = useState(null);
  const [selectedPassword, setSelectedPassword] = useState(null);
  const [showMasterPassword, setShowMasterPassword] = useState(false);
  const [masterPassword, setMasterPassword] = useState('');
  const [showDecryptedPassword, setShowDecryptedPassword] = useState(false);
  const [decryptedPassword, setDecryptedPassword] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [showItemsList, setShowItemsList] = useState(true);
  const [showSettingsModal, setShowSettingsModal] = useState(false);
  const [settingsForm, setSettingsForm] = useState({
    email: '',
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  });
  const [theme, setTheme] = useState(localStorage.getItem('theme') || 'dark');
  const [isOffline, setIsOffline] = useState(false);
  
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  // Apply theme on mount and when it changes
  useEffect(() => {
    document.body.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  }, [theme]);

  // Form state
  const [formData, setFormData] = useState({
    website: '',
    username: '',
    email: '',
    password: '',
    notes: '',
    category: '',
    favorite: false
  });

  useEffect(() => {
    loadPasswords();
    
    // Poll for updates every 5 seconds (silent refresh)
    const intervalId = setInterval(() => {
      loadPasswords(true);
    }, 5000);
    
    // Cleanup interval on component unmount
    return () => clearInterval(intervalId);
  }, []);

  const loadPasswords = async (silent = false) => {
    try {
      const response = await passwordAPI.getAll();
      setPasswords(response.data.passwords);
      
      // Check if data is from cache (offline mode)
      if (response.data.fromCache) {
        setIsOffline(true);
        if (!silent) {
          console.log('📦 Displaying cached passwords (offline mode)');
        }
      } else {
        setIsOffline(false);
      }
      
      if (!silent) {
        setLoading(false);
      }
    } catch (error) {
      console.error('Error loading passwords:', error);
      setIsOffline(true);
      if (!silent) {
        setLoading(false);
      }
    }
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const openSettingsModal = () => {
    setSettingsForm({
      email: user?.email || '',
      currentPassword: '',
      newPassword: '',
      confirmPassword: ''
    });
    setShowSettingsModal(true);
  };

  const closeSettingsModal = () => {
    setShowSettingsModal(false);
    setSettingsForm({
      email: '',
      currentPassword: '',
      newPassword: '',
      confirmPassword: ''
    });
  };

  const handleSettingsChange = (e) => {
    setSettingsForm({
      ...settingsForm,
      [e.target.name]: e.target.value
    });
  };

  const handleUpdateSettings = async (e) => {
    e.preventDefault();
    
    try {
      const updates = {};
      
      // Check if email changed
      if (settingsForm.email && settingsForm.email !== user?.email) {
        updates.email = settingsForm.email;
      }
      
      // Check if password is being changed
      if (settingsForm.newPassword) {
        if (settingsForm.newPassword !== settingsForm.confirmPassword) {
          alert('New passwords do not match!');
          return;
        }
        if (settingsForm.newPassword.length < 6) {
          alert('New password must be at least 6 characters!');
          return;
        }
        if (!settingsForm.currentPassword) {
          alert('Current password is required to change password!');
          return;
        }
        updates.currentPassword = settingsForm.currentPassword;
        updates.newPassword = settingsForm.newPassword;
      }
      
      // If email changed, current password is required
      if (updates.email && !settingsForm.currentPassword) {
        alert('Current password is required to change email!');
        return;
      }
      
      if (updates.email || updates.newPassword) {
        updates.currentPassword = settingsForm.currentPassword;
      }
      
      if (Object.keys(updates).length === 0 || (Object.keys(updates).length === 1 && updates.currentPassword)) {
        alert('No changes to save!');
        return;
      }
      
      const response = await authAPI.updateProfile(updates);
      alert(response.message || 'Settings updated successfully!');
      
      // If password was changed, log out user
      if (updates.newPassword) {
        alert('Password changed successfully! Please log in again.');
        handleLogout();
      } else {
        closeSettingsModal();
        // Refresh user data if needed
        window.location.reload();
      }
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to update settings');
    }
  };

  const openModal = (password = null) => {
    if (password) {
      setEditingPassword(password);
      setFormData({
        website: password.website,
        username: password.username || '',
        email: password.email || '',
        password: '',
        notes: password.notes || '',
        category: password.category || '',
        favorite: password.favorite || false
      });
    } else {
      setEditingPassword(null);
      setFormData({
        website: '',
        username: '',
        email: '',
        password: '',
        notes: '',
        category: '',
        favorite: false
      });
    }
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setEditingPassword(null);
    setFormData({
      website: '',
      username: '',
      email: '',
      password: '',
      notes: '',
      category: '',
      favorite: false
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    try {
      if (editingPassword) {
        await passwordAPI.update(editingPassword.id, formData);
      } else {
        await passwordAPI.create(formData);
      }
      
      loadPasswords();
      closeModal();
    } catch (error) {
      console.error('Error saving password:', error);
      alert('Error saving password');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this password?')) {
      try {
        await passwordAPI.delete(id);
        loadPasswords();
        setSelectedPassword(null);
      } catch (error) {
        console.error('Error deleting password:', error);
        alert('Error deleting password');
      }
    }
  };

  const selectPassword = async (password) => {
    setSelectedPassword(password);
    setShowDecryptedPassword(false);
    setDecryptedPassword('');
    setMasterPassword('');
    // On mobile, hide items list when viewing details
    if (window.innerWidth <= 768) {
      setShowItemsList(false);
    }
  };

  const verifyAndShowPassword = async () => {
    if (!masterPassword) {
      alert('Please enter your master password');
      return;
    }

    try {
      // If offline, skip master password verification and show cached password
      if (isOffline) {
        console.log('📡 Offline mode - showing cached password without verification');
        // Password is already in the cached data
        if (selectedPassword && selectedPassword.password) {
          setDecryptedPassword(selectedPassword.password);
          setShowDecryptedPassword(true);
          setShowMasterPassword(false);
          setMasterPassword('');
        } else {
          alert('Password not available offline. Please reconnect to server.');
          setMasterPassword('');
        }
        return;
      }

      // Verify master password (online mode)
      const verifyResponse = await authAPI.verifyPassword(masterPassword);
      
      if (verifyResponse.data.valid) {
        // Get decrypted password
        const response = await passwordAPI.getOne(selectedPassword.id);
        const password = response.data.password.decrypted_password || response.data.password;
        setDecryptedPassword(password);
        setShowDecryptedPassword(true);
        setShowMasterPassword(false);
        setMasterPassword('');
      }
    } catch (error) {
      if (error.response && error.response.status === 401) {
        alert('Invalid master password');
      } else {
        console.error('Error verifying password:', error);
        alert('Error verifying password');
      }
      setMasterPassword('');
    }
  };

  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text);
    alert('Copied to clipboard!');
  };

  const generatePassword = async () => {
    try {
      const response = await passwordAPI.generate(16);
      setFormData({ ...formData, password: response.data.password });
    } catch (error) {
      console.error('Error generating password:', error);
    }
  };

  const filteredPasswords = passwords.filter(pwd => {
    const matchesSearch = pwd.website.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (pwd.username && pwd.username.toLowerCase().includes(searchTerm.toLowerCase()));
    const matchesCategory = selectedCategory === 'all' || 
                           (selectedCategory === 'favorites' && pwd.favorite === 1) ||
                           pwd.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  const categories = [...new Set(passwords.map(p => p.category).filter(Boolean))];
  const favoriteCount = passwords.filter(p => p.favorite === 1).length;

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  return (
    <div className="dashboard-bitwarden">
      {/* Mobile Overlay */}
      {mobileMenuOpen && (
        <div className="mobile-overlay" onClick={() => setMobileMenuOpen(false)} />
      )}

      {/* Sidebar */}
      <aside className={`sidebar ${sidebarCollapsed ? 'collapsed' : ''} ${mobileMenuOpen ? 'mobile-open' : ''}`}>
        <div className="sidebar-header">
          <div className="logo">
            <FiLock className="logo-icon" />
            {!sidebarCollapsed && <span>PSW</span>}
          </div>
          <div className="sidebar-header-actions">
            <button 
              className="btn-collapse desktop-only" 
              onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
              title={sidebarCollapsed ? "Expand" : "Collapse"}
            >
              {sidebarCollapsed ? <FiChevronRight /> : <FiChevronLeft />}
            </button>
            <button 
              className="btn-collapse mobile-only" 
              onClick={() => setMobileMenuOpen(false)}
            >
              <FiX />
            </button>
          </div>
        </div>

        <div className="sidebar-content">
          <div className="sidebar-section">
            <button 
              className={`sidebar-item ${selectedCategory === 'all' ? 'active' : ''}`}
              onClick={() => {
                setSelectedCategory('all');
                setMobileMenuOpen(false);
              }}
            >
              <FiList className="sidebar-icon" />
              {!sidebarCollapsed && <span>All Items</span>}
              {!sidebarCollapsed && <span className="item-count">{passwords.length}</span>}
            </button>

            <button 
              className={`sidebar-item ${selectedCategory === 'favorites' ? 'active' : ''}`}
              onClick={() => {
                setSelectedCategory('favorites');
                setMobileMenuOpen(false);
              }}
            >
              <FiStar className="sidebar-icon" />
              {!sidebarCollapsed && <span>Favorites</span>}
              {!sidebarCollapsed && <span className="item-count">{favoriteCount}</span>}
            </button>
          </div>

          {!sidebarCollapsed && categories.length > 0 && (
            <div className="sidebar-section">
              <div className="sidebar-section-title">
                <FiFolder /> Categories
              </div>
              {categories.map(cat => (
                <button 
                  key={cat}
                  className={`sidebar-item ${selectedCategory === cat ? 'active' : ''}`}
                  onClick={() => {
                    setSelectedCategory(cat);
                    setMobileMenuOpen(false);
                  }}
                >
                  <FiFolder className="sidebar-icon" />
                  <span>{cat}</span>
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Offline Mode Indicator in Sidebar */}
        {isOffline && !sidebarCollapsed && (
          <div className="sidebar-offline-banner">
            <div className="offline-icon-small">⚠️</div>
            <div className="offline-text-small">
              <strong>Offline</strong>
              <span>Viewing cached data</span>
            </div>
          </div>
        )}

        <div className="sidebar-footer">
          <div className="user-section">
            <div className="user-info">
              <div className="user-avatar">
                <FiUser />
              </div>
              {!sidebarCollapsed && (
                <span className="user-name">{user?.email}</span>
              )}
            </div>
            <div className="user-actions">
              <button 
                onClick={openSettingsModal} 
                className="btn-icon-settings" 
                title="Settings"
              >
                <FiSettings />
              </button>
              <button 
                onClick={handleLogout} 
                className="btn-icon-logout" 
                title="Logout"
              >
                <FiLogOut />
              </button>
            </div>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="main-content">
        {/* Toolbar */}
        <div className="toolbar-bitwarden">
          <button 
            className="btn-mobile-menu"
            onClick={() => setMobileMenuOpen(true)}
          >
            <FiMenu />
          </button>

          <div className="search-bar">
            <FiSearch className="search-icon" />
            <input
              type="text"
              placeholder="Search vault..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="search-input-bitwarden"
            />
          </div>

          <button onClick={() => openModal()} className="btn-new-item">
            <FiPlus />
            <span className="btn-text">New Item</span>
          </button>
        </div>

        {/* Content Grid */}
        <div className="content-grid">
          {/* Items List */}
          <div className={`items-list ${!showItemsList ? 'mobile-hidden' : ''}`}>
            <div className="items-header">
              <h2>{selectedCategory === 'all' ? 'All Items' : 
                   selectedCategory === 'favorites' ? 'Favorites' : selectedCategory}</h2>
              <span className="items-count">{filteredPasswords.length} items</span>
            </div>

            <div className="items-container">
              {filteredPasswords.length === 0 ? (
                <div className="no-items">
                  <FiLock size={48} />
                  <p>No items found</p>
                  <button onClick={() => openModal()} className="btn-primary">
                    Add your first password
                  </button>
                </div>
              ) : (
                filteredPasswords.map(password => (
                  <div 
                    key={password.id} 
                    className={`item-card ${selectedPassword?.id === password.id ? 'selected' : ''}`}
                    onClick={() => selectPassword(password)}
                  >
                    <div className="item-icon">
                      <FiGlobe />
                    </div>
                    <div className="item-info">
                      <div className="item-name">
                        {password.website}
                        {password.favorite === 1 && <FiStar className="favorite-star" />}
                      </div>
                      <div className="item-username">{password.username || password.email || 'No username'}</div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Item Details */}
          <div className={`item-details ${!showItemsList ? 'mobile-visible' : ''}`}>
            {selectedPassword ? (
              <>
                <div className="details-header">
                  <button 
                    className="btn-back-mobile"
                    onClick={() => setShowItemsList(true)}
                  >
                    <FiChevronLeft /> Back
                  </button>
                  <div className="details-title">
                    <FiGlobe className="details-icon" />
                    <h2>{selectedPassword.website}</h2>
                  </div>
                  <div className="details-actions">
                    <button onClick={() => openModal(selectedPassword)} className="btn-icon" title="Edit">
                      <FiEdit2 />
                    </button>
                    <button onClick={() => handleDelete(selectedPassword.id)} className="btn-icon btn-danger" title="Delete">
                      <FiTrash2 />
                    </button>
                  </div>
                </div>

                <div className="details-body">
                  {selectedPassword.username && (
                    <div className="detail-field">
                      <label>Username</label>
                      <div className="field-value">
                        <span>{selectedPassword.username}</span>
                        <button 
                          onClick={() => copyToClipboard(selectedPassword.username)} 
                          className="btn-copy-small"
                          title="Copy"
                        >
                          <FiCopy />
                        </button>
                      </div>
                    </div>
                  )}

                  {selectedPassword.email && (
                    <div className="detail-field">
                      <label>Email</label>
                      <div className="field-value">
                        <span>{selectedPassword.email}</span>
                        <button 
                          onClick={() => copyToClipboard(selectedPassword.email)} 
                          className="btn-copy-small"
                          title="Copy"
                        >
                          <FiCopy />
                        </button>
                      </div>
                    </div>
                  )}

                  <div className="detail-field">
                    <label>Password</label>
                    {!showDecryptedPassword ? (
                      <div className="password-verify">
                        <p className="password-hint">Enter your master password to view</p>
                        <div className="master-password-input">
                          <input
                            type={showMasterPassword ? "text" : "password"}
                            value={masterPassword}
                            onChange={(e) => setMasterPassword(e.target.value)}
                            placeholder="Master password"
                            onKeyPress={(e) => e.key === 'Enter' && verifyAndShowPassword()}
                          />
                          <button 
                            onClick={() => setShowMasterPassword(!showMasterPassword)} 
                            className="btn-toggle-visibility"
                          >
                            {showMasterPassword ? <FiEyeOff /> : <FiEye />}
                          </button>
                          <button 
                            onClick={verifyAndShowPassword}
                            className="btn-verify"
                          >
                            Show
                          </button>
                        </div>
                      </div>
                    ) : (
                      <div className="field-value">
                        <span className="password-value">{decryptedPassword}</span>
                        <button 
                          onClick={() => copyToClipboard(decryptedPassword)} 
                          className="btn-copy-small"
                          title="Copy"
                        >
                          <FiCopy />
                        </button>
                        <button 
                          onClick={() => {
                            setShowDecryptedPassword(false);
                            setDecryptedPassword('');
                          }} 
                          className="btn-copy-small"
                          title="Hide"
                        >
                          <FiEyeOff />
                        </button>
                      </div>
                    )}
                  </div>

                  {selectedPassword.category && (
                    <div className="detail-field">
                      <label>Category</label>
                      <div className="field-value">
                        <span className="category-tag">{selectedPassword.category}</span>
                      </div>
                    </div>
                  )}

                  {selectedPassword.notes && (
                    <div className="detail-field">
                      <label>Notes</label>
                      <div className="field-value">
                        <p className="notes-text">{selectedPassword.notes}</p>
                      </div>
                    </div>
                  )}

                  <div className="detail-field">
                    <label>Created</label>
                    <div className="field-value">
                      <span className="date-text">
                        {new Date(selectedPassword.created_at).toLocaleDateString()}
                      </span>
                    </div>
                  </div>
                </div>
              </>
            ) : (
              <div className="no-selection">
                <FiLock size={64} />
                <p>Select an item to view details</p>
              </div>
            )}
          </div>
        </div>
      </main>

      {/* Modal for Add/Edit */}
      {showModal && (
        <div className="modal-overlay" onClick={closeModal}>
          <div className="modal-bitwarden" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header-bitwarden">
              <h2>{editingPassword ? 'Edit Item' : 'Add New Item'}</h2>
              <button onClick={closeModal} className="btn-close">×</button>
            </div>
            
            <form onSubmit={handleSubmit} className="modal-form">
              <div className="form-group">
                <label>Name *</label>
                <input
                  type="text"
                  value={formData.website}
                  onChange={(e) => setFormData({ ...formData, website: e.target.value })}
                  required
                  placeholder="e.g., facebook.com"
                />
              </div>

              <div className="form-group">
                <label>Username</label>
                <input
                  type="text"
                  value={formData.username}
                  onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                  placeholder="Username"
                />
              </div>

              <div className="form-group">
                <label>Email</label>
                <input
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  placeholder="Email address"
                />
              </div>

              <div className="form-group">
                <label>Password *</label>
                <div className="password-input-group">
                  <input
                    type="text"
                    value={formData.password}
                    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                    required={!editingPassword}
                    placeholder={editingPassword ? "Leave blank to keep current password" : "Password"}
                  />
                  <button type="button" onClick={generatePassword} className="btn-generate-inline">
                    Generate
                  </button>
                </div>
              </div>

              <div className="form-group">
                <label>Category</label>
                <input
                  type="text"
                  value={formData.category}
                  onChange={(e) => setFormData({ ...formData, category: e.target.value })}
                  placeholder="e.g., Social Media, Banking"
                />
              </div>

              <div className="form-group">
                <label>Notes</label>
                <textarea
                  value={formData.notes}
                  onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                  placeholder="Additional notes"
                  rows="3"
                />
              </div>

              <div className="form-group checkbox-group">
                <label className="checkbox-label">
                  <input
                    type="checkbox"
                    checked={formData.favorite}
                    onChange={(e) => setFormData({ ...formData, favorite: e.target.checked })}
                  />
                  <span>Mark as favorite</span>
                </label>
              </div>

              <div className="modal-actions-bitwarden">
                <button type="button" onClick={closeModal} className="btn-cancel">
                  Cancel
                </button>
                <button type="submit" className="btn-save">
                  {editingPassword ? 'Update' : 'Save'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Settings Modal */}
      {showSettingsModal && (
        <div className="modal-overlay" onClick={closeSettingsModal}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2><FiSettings /> User Settings</h2>
              <button onClick={closeSettingsModal} className="btn-close-modal">
                <FiX />
              </button>
            </div>

            <form onSubmit={handleUpdateSettings} className="modal-body">
              <div className="settings-section">
                <h3 className="settings-section-title">Appearance</h3>
                <div className="theme-toggle-group">
                  <label className="theme-label">Theme</label>
                  <div className="theme-toggle-buttons">
                    <button
                      type="button"
                      className={`theme-btn ${theme === 'dark' ? 'active' : ''}`}
                      onClick={() => setTheme('dark')}
                    >
                      Dark
                    </button>
                    <button
                      type="button"
                      className={`theme-btn ${theme === 'light' ? 'active' : ''}`}
                      onClick={() => setTheme('light')}
                    >
                      Light
                    </button>
                  </div>
                </div>
              </div>

              <div className="settings-divider">
                <span>Account Settings</span>
              </div>

              <div className="form-group">
                <label>Email</label>
                <input
                  type="email"
                  name="email"
                  value={settingsForm.email}
                  onChange={handleSettingsChange}
                  className="form-input"
                  placeholder="Enter new email"
                />
              </div>

              <div className="settings-divider">
                <span>Change Password</span>
              </div>

              <div className="form-group">
                <label>Current Password *</label>
                <input
                  type="password"
                  name="currentPassword"
                  value={settingsForm.currentPassword}
                  onChange={handleSettingsChange}
                  className="form-input"
                  placeholder="Required for any changes"
                />
              </div>

              <div className="form-group">
                <label>New Password</label>
                <input
                  type="password"
                  name="newPassword"
                  value={settingsForm.newPassword}
                  onChange={handleSettingsChange}
                  className="form-input"
                  placeholder="Leave blank to keep current"
                />
              </div>

              <div className="form-group">
                <label>Confirm New Password</label>
                <input
                  type="password"
                  name="confirmPassword"
                  value={settingsForm.confirmPassword}
                  onChange={handleSettingsChange}
                  className="form-input"
                  placeholder="Confirm new password"
                />
              </div>

              <div className="modal-footer">
                <button type="button" onClick={closeSettingsModal} className="btn-cancel">
                  Cancel
                </button>
                <button type="submit" className="btn-save">
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Dashboard;
