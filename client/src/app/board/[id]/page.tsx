'use client';

import { useEffect, useState, useRef } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useSocket } from '@/contexts/SocketContext';
import { boardService, listService, cardService } from '@/services/api';
import { DragDropContext, Droppable, Draggable, DropResult } from '@hello-pangea/dnd';
import { Plus, ArrowLeft, Users, Tag, Settings, LogOut, Moon, Sun, ChevronDown } from 'lucide-react';

interface Card {
  id: number;
  title: string;
  description?: string;
  position: number;
  due_date?: string;
  labels: Array<{ id: number; name: string; color: string }>;
}

interface List {
  id: number;
  title: string;
  position: number;
  color?: string;
  cards: Card[];
}

interface Board {
  id: number;
  title: string;
  description?: string;
  background: string;
  lists: List[];
  members: Array<{ id: number; name: string; email: string; role: string }>;
}

export default function BoardPage() {
  const params = useParams();
  const router = useRouter();
  const { user, setUser, logout, loading: authLoading } = useAuth();
  const { socket } = useSocket();
  const [board, setBoard] = useState<Board | null>(null);
  const [loading, setLoading] = useState(true);
  const [showNewList, setShowNewList] = useState(false);
  const [newListTitle, setNewListTitle] = useState('');
  const [showNewCard, setShowNewCard] = useState<number | null>(null);
  const [newCardTitle, setNewCardTitle] = useState('');
  const [showMembersModal, setShowMembersModal] = useState(false);
  const [newMemberEmail, setNewMemberEmail] = useState('');
  const [addMemberError, setAddMemberError] = useState('');
  const [showSettingsModal, setShowSettingsModal] = useState(false);
  const [editTitle, setEditTitle] = useState('');
  const [editDescription, setEditDescription] = useState('');
  const [editBackground, setEditBackground] = useState('');
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const [darkMode, setDarkMode] = useState(false);
  const [showEditProfile, setShowEditProfile] = useState(false);
  const [editName, setEditName] = useState('');
  const [showListColorPicker, setShowListColorPicker] = useState<number | null>(null);
  const profileMenuRef = useRef<HTMLDivElement>(null);

  const colors = [
    '#0079bf', '#d29034', '#519839', '#b04632', '#89609e',
    '#cd5a91', '#4bbf6b', '#00aecc', '#838c91'
  ];

  const listColors = [
    { bg: 'bg-gray-100 dark:bg-gray-800', name: 'default', preview: '#e5e7eb' },
    { bg: 'bg-blue-200/80', name: 'blue', preview: '#93c5fd' },
    { bg: 'bg-green-200/80', name: 'green', preview: '#86efac' },
    { bg: 'bg-yellow-200/80', name: 'yellow', preview: '#fde047' },
    { bg: 'bg-red-200/80', name: 'red', preview: '#fca5a5' },
    { bg: 'bg-purple-200/80', name: 'purple', preview: '#d8b4fe' },
    { bg: 'bg-pink-200/80', name: 'pink', preview: '#fbcfe8' },
    { bg: 'bg-orange-200/80', name: 'orange', preview: '#fed7aa' },
  ];

  const cardColors = [
    '#60a5fa', '#34d399', '#fbbf24', '#f87171', '#a78bfa',
    '#fb923c', '#2dd4bf', '#f472b6', '#facc15', '#38bdf8'
  ];

  const getCardColor = (cardId: number) => {
    return cardColors[cardId % cardColors.length];
  };

  const boardId = parseInt(params.id as string);

  useEffect(() => {
    if (!authLoading && !user) {
      router.push('/login');
    } else if (user) {
      fetchBoard();
    }
  }, [user, authLoading, boardId, router]);

  useEffect(() => {
    // Load dark mode preference
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme === 'dark') {
      setDarkMode(true);
      document.documentElement.classList.add('dark');
    }
  }, []);

  useEffect(() => {
    // Initialize editName when user data is available
    if (user) {
      setEditName(user.name);
    }
  }, [user]);

  useEffect(() => {
    // Close dropdown when clicking outside
    const handleClickOutside = (event: MouseEvent) => {
      if (profileMenuRef.current && !profileMenuRef.current.contains(event.target as Node)) {
        setShowProfileMenu(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  useEffect(() => {
    if (!socket || !boardId) return;

    socket.emit('join-board', boardId);

    socket.on('list-created', ({ list }: any) => {
      setBoard((prev) => {
        if (!prev) return prev;
        return { ...prev, lists: [...prev.lists, list].sort((a, b) => a.position - b.position) };
      });
    });

    socket.on('card-created', ({ card, listId }: any) => {
      setBoard((prev) => {
        if (!prev) return prev;
        const lists = prev.lists.map((list) => {
          if (list.id === listId) {
            return { ...list, cards: [...list.cards, card].sort((a, b) => a.position - b.position) };
          }
          return list;
        });
        return { ...prev, lists };
      });
    });

    socket.on('card-updated', ({ cardId, updates }: any) => {
      setBoard((prev) => {
        if (!prev) return prev;
        const lists = prev.lists.map((list) => ({
          ...list,
          cards: list.cards.map((card) => 
            card.id === cardId ? { ...card, ...updates } : card
          ),
        }));
        return { ...prev, lists };
      });
    });

    socket.on('list-deleted', ({ listId }: any) => {
      setBoard((prev) => {
        if (!prev) return prev;
        return { ...prev, lists: prev.lists.filter((list) => list.id !== listId) };
      });
    });

    socket.on('card-deleted', ({ cardId }: any) => {
      setBoard((prev) => {
        if (!prev) return prev;
        const lists = prev.lists.map((list) => ({
          ...list,
          cards: list.cards.filter((card) => card.id !== cardId),
        }));
        return { ...prev, lists };
      });
    });

    socket.on('member-added', ({ user }: any) => {
      setBoard((prev) => {
        if (!prev) return prev;
        return { ...prev, members: [...prev.members, user] };
      });
    });

    return () => {
      socket.emit('leave-board', boardId);
      socket.off('list-created');
      socket.off('card-created');
      socket.off('card-updated');
      socket.off('list-deleted');
      socket.off('card-deleted');
      socket.off('member-added');
    };
  }, [socket, boardId]);

  const fetchBoard = async () => {
    try {
      const response = await boardService.getOne(boardId);
      setBoard(response.board);
      setEditTitle(response.board.title);
      setEditDescription(response.board.description || '');
      setEditBackground(response.board.background);
    } catch (error) {
      console.error('Error fetching board:', error);
      router.push('/boards');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateList = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newListTitle.trim()) return;

    try {
      await listService.create({ title: newListTitle, boardId });
      setNewListTitle('');
      setShowNewList(false);
    } catch (error) {
      console.error('Error creating list:', error);
    }
  };

  const handleCreateCard = async (e: React.FormEvent, listId: number) => {
    e.preventDefault();
    if (!newCardTitle.trim()) return;

    try {
      await cardService.create({ title: newCardTitle, listId });
      setNewCardTitle('');
      setShowNewCard(null);
    } catch (error) {
      console.error('Error creating card:', error);
    }
  };

  const handleDeleteList = async (listId: number) => {
    if (!confirm('Are you sure you want to delete this list?')) return;
    
    // Optimistic update - remove list immediately from UI
    setBoard((prev) => {
      if (!prev) return prev;
      return { ...prev, lists: prev.lists.filter((list) => list.id !== listId) };
    });

    try {
      await listService.delete(listId);
    } catch (error) {
      console.error('Error deleting list:', error);
      fetchBoard(); // Revert on error
    }
  };

  const handleChangeListColor = async (listId: number, color: string) => {
    // Optimistic update
    setBoard((prev) => {
      if (!prev) return prev;
      return {
        ...prev,
        lists: prev.lists.map((list) =>
          list.id === listId ? { ...list, color } : list
        ),
      };
    });

    try {
      await listService.update(listId, { color });
      setShowListColorPicker(null);
    } catch (error) {
      console.error('Error updating list color:', error);
      fetchBoard(); // Revert on error
    }
  };

  const handleAddMember = async (e: React.FormEvent) => {
    e.preventDefault();
    setAddMemberError('');
    
    try {
      await boardService.addMember(boardId, newMemberEmail);
      setNewMemberEmail('');
      fetchBoard(); // Refresh to get updated members
    } catch (error: any) {
      setAddMemberError(error.response?.data?.message || 'Failed to add member');
    }
  };

  const handleDeleteCard = async (cardId: number) => {
    if (!confirm('Are you sure you want to delete this card?')) return;
    
    // Optimistic update - remove card immediately from UI
    setBoard((prev) => {
      if (!prev) return prev;
      const lists = prev.lists.map((list) => ({
        ...list,
        cards: list.cards.filter((card) => card.id !== cardId),
      }));
      return { ...prev, lists };
    });

    try {
      await cardService.delete(cardId);
    } catch (error) {
      console.error('Error deleting card:', error);
      fetchBoard(); // Revert on error
    }
  };

  const handleUpdateBoard = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      await boardService.update(boardId, {
        title: editTitle,
        description: editDescription,
        background: editBackground
      });
      
      setBoard((prev) => {
        if (!prev) return prev;
        return {
          ...prev,
          title: editTitle,
          description: editDescription,
          background: editBackground
        };
      });
      
      setShowSettingsModal(false);
    } catch (error) {
      console.error('Error updating board:', error);
    }
  };

  const handleDeleteBoard = async () => {
    if (!confirm('Are you sure you want to delete this board? This action cannot be undone.')) return;
    
    try {
      await boardService.delete(boardId);
      router.push('/boards');
    } catch (error: any) {
      alert(error.response?.data?.message || 'Failed to delete board');
    }
  };

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  const toggleDarkMode = () => {
    const newMode = !darkMode;
    setDarkMode(newMode);
    if (newMode) {
      document.documentElement.classList.add('dark');
      localStorage.setItem('theme', 'dark');
    } else {
      document.documentElement.classList.remove('dark');
      localStorage.setItem('theme', 'light');
    }
  };

  const handleUpdateProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!editName.trim()) {
      alert('Name cannot be empty');
      return;
    }

    try {
      const response = await fetch('http://localhost:5000/api/auth/profile', {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        },
        body: JSON.stringify({ name: editName.trim() })
      });

      if (!response.ok) {
        throw new Error('Failed to update profile');
      }

      const data = await response.json();
      
      // Update user in AuthContext
      if (setUser) {
        setUser(data.user);
      }
      
      setShowEditProfile(false);
      alert('Profile updated successfully!');
    } catch (error) {
      console.error('Error updating profile:', error);
      alert('Failed to update profile. Please try again.');
    }
  };

  const handleDragEnd = async (result: DropResult) => {
    const { destination, source, draggableId, type } = result;

    if (!destination) return;
    if (destination.droppableId === source.droppableId && destination.index === source.index) return;

    if (type === 'card') {
      const sourceListId = parseInt(source.droppableId.split('-')[1]);
      const destListId = parseInt(destination.droppableId.split('-')[1]);
      const cardId = parseInt(draggableId.split('-')[1]);

      // Optimistic update
      setBoard((prev) => {
        if (!prev) return prev;

        const lists = prev.lists.map(l => ({
          ...l,
          cards: [...l.cards]
        }));
        
        const sourceList = lists.find((l) => l.id === sourceListId);
        const destList = lists.find((l) => l.id === destListId);

        if (!sourceList || !destList) return prev;

        const [movedCard] = sourceList.cards.splice(source.index, 1);
        if (!movedCard) return prev;

        destList.cards.splice(destination.index, 0, { ...movedCard });

        // Update positions
        sourceList.cards.forEach((card, idx) => {
          card.position = idx;
        });
        destList.cards.forEach((card, idx) => {
          card.position = idx;
        });

        return { ...prev, lists };
      });

      try {
        await cardService.update(cardId, {
          listId: destListId,
          position: destination.index,
        });
      } catch (error) {
        console.error('Error updating card:', error);
        fetchBoard(); // Revert on error
      }
    }
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-xl">Loading...</div>
      </div>
    );
  }

  if (!board) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-xl">Board not found</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col" style={{ backgroundColor: board.background }}>
      {/* Header */}
      <nav className="bg-black/20 backdrop-blur-sm border-b border-white/10">
        <div className="px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <button
                onClick={() => router.push('/boards')}
                className="text-white hover:bg-white/20 p-2 rounded transition"
              >
                <ArrowLeft className="w-5 h-5" />
              </button>
              <h1 className="text-xl font-bold text-white">{board.title}</h1>
              {board.description && (
                <p className="text-white/80 text-sm">{board.description}</p>
              )}
            </div>
            <div className="flex items-center gap-2">
              <button 
                onClick={() => setShowMembersModal(true)}
                className="flex items-center gap-2 px-3 py-2 bg-white/20 hover:bg-white/30 text-white rounded transition text-sm"
              >
                <Users className="w-4 h-4" />
                {board.members.length} Members
              </button>
              <button 
                onClick={() => setShowSettingsModal(true)}
                className="flex items-center gap-2 px-3 py-2 bg-white/20 hover:bg-white/30 text-white rounded transition text-sm"
                title="Board Settings"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </button>

              <div className="relative" ref={profileMenuRef}>
                <button
                  onClick={() => setShowProfileMenu(!showProfileMenu)}
                  className="flex items-center gap-2 px-3 py-2 bg-white/20 hover:bg-white/30 text-white rounded transition text-sm"
                >
                  <div className="w-7 h-7 rounded-full bg-white/30 flex items-center justify-center text-white font-semibold text-sm">
                    {user?.name.charAt(0).toUpperCase()}
                  </div>
                  <span className="text-sm font-medium">{user?.name}</span>
                  <ChevronDown className={`w-4 h-4 transition-transform ${showProfileMenu ? 'rotate-180' : ''}`} />
                </button>

                {/* Dropdown Menu */}
                {showProfileMenu && (
                  <div className="absolute right-0 mt-2 w-56 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 py-1 z-50">
                    <div className="px-4 py-3 border-b border-gray-100 dark:border-gray-700">
                      <p className="text-sm font-semibold text-gray-900 dark:text-white">{user?.name}</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">{user?.email}</p>
                    </div>
                    
                    <button
                      onClick={() => {
                        setShowProfileMenu(false);
                        setShowEditProfile(true);
                      }}
                      className="w-full flex items-center gap-3 px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 transition"
                    >
                      <Settings className="w-4 h-4" />
                      Edit Account
                    </button>

                    <button
                      onClick={toggleDarkMode}
                      className="w-full flex items-center gap-3 px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 transition"
                    >
                      {darkMode ? (
                        <>
                          <Sun className="w-4 h-4" />
                          Light Mode
                        </>
                      ) : (
                        <>
                          <Moon className="w-4 h-4" />
                          Dark Mode
                        </>
                      )}
                    </button>

                    <div className="border-t border-gray-100 dark:border-gray-700 mt-1 pt-1">
                      <button
                        onClick={() => {
                          setShowProfileMenu(false);
                          handleLogout();
                        }}
                        className="w-full flex items-center gap-3 px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 transition"
                      >
                        <LogOut className="w-4 h-4" />
                        Logout
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </nav>

      {/* Board Content */}
      <div className="flex-1 overflow-x-auto p-4">
        <DragDropContext onDragEnd={handleDragEnd}>
          <div className="flex gap-4 h-full">
            {board.lists.map((list, listIndex) => (
              <Droppable key={list.id} droppableId={`list-${list.id}`} type="card">
                {(provided, snapshot) => {
                  const listColorClass = listColors.find(c => c.name === (list.color || 'default'))?.bg || listColors[0].bg;
                  return (
                  <div
                    ref={provided.innerRef}
                    {...provided.droppableProps}
                    className={`${listColorClass} rounded-lg p-3 w-72 flex-shrink-0 flex flex-col max-h-full ${
                      snapshot.isDraggingOver ? 'ring-2 ring-blue-400' : ''
                    }`}
                  >
                    <div className="flex items-center justify-between mb-3">
                      <h3 className="font-semibold text-gray-800 dark:text-gray-200">{list.title}</h3>
                      <div className="flex items-center gap-1">
                        <div className="relative">
                          <button
                            onClick={() => setShowListColorPicker(showListColorPicker === list.id ? null : list.id)}
                            className="text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 p-1 rounded hover:bg-gray-200 dark:hover:bg-gray-600 transition"
                            title="Change color"
                          >
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                            </svg>
                          </button>
                          
                          {showListColorPicker === list.id && (
                            <div className="absolute top-8 right-0 bg-white dark:bg-gray-800 rounded-lg shadow-xl border border-gray-200 dark:border-gray-700 p-3 z-50 w-48">
                              <div className="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-2">List Color</div>
                              <div className="grid grid-cols-4 gap-2">
                                {listColors.map((colorOption) => (
                                  <button
                                    key={colorOption.name}
                                    onClick={() => handleChangeListColor(list.id, colorOption.name)}
                                    className={`w-10 h-10 rounded-lg ${colorOption.bg} border-2 ${
                                      (list.color || 'default') === colorOption.name 
                                        ? 'border-blue-500 ring-2 ring-blue-300' 
                                        : 'border-gray-300 dark:border-gray-600 hover:border-gray-400'
                                    } transition`}
                                    title={colorOption.name}
                                  />
                                ))}
                              </div>
                            </div>
                          )}
                        </div>
                        <button
                          onClick={() => handleDeleteList(list.id)}
                          className="text-gray-500 dark:text-gray-400 hover:text-red-600 dark:hover:text-red-400 p-1 rounded hover:bg-gray-200 dark:hover:bg-gray-600 transition"
                          title="Delete list"
                        >
                          ✕
                        </button>
                      </div>
                    </div>

                    <div className="flex-1 overflow-y-auto space-y-2 mb-2">
                      {list.cards.map((card, cardIndex) => (
                        <Draggable key={card.id} draggableId={`card-${card.id}`} index={cardIndex}>
                          {(provided, snapshot) => (
                            <div
                              ref={provided.innerRef}
                              {...provided.draggableProps}
                              {...provided.dragHandleProps}
                              className={`bg-white dark:bg-gray-700 rounded-md p-3 shadow-sm hover:shadow-md dark:shadow-gray-900/50 dark:hover:shadow-gray-900/70 transition group border-l-4 ${
                                snapshot.isDragging ? 'shadow-lg dark:shadow-gray-900/80' : ''
                              }`}
                              style={{
                                ...provided.draggableProps.style,
                                borderLeftColor: getCardColor(card.id)
                              }}
                            >
                              <div className="flex items-start justify-between gap-2">
                                <div className="flex-1">
                                  <div className="text-gray-800 dark:text-gray-200 font-medium mb-2">{card.title}</div>
                                  {card.labels && card.labels.length > 0 && (
                                    <div className="flex flex-wrap gap-1">
                                      {card.labels.map((label) => (
                                        <span
                                          key={label.id}
                                          className="px-2 py-1 rounded text-xs font-medium text-white"
                                          style={{ backgroundColor: label.color }}
                                        >
                                          {label.name}
                                        </span>
                                      ))}
                                    </div>
                                  )}
                                </div>
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    handleDeleteCard(card.id);
                                  }}
                                  className="opacity-0 group-hover:opacity-100 text-gray-400 dark:text-gray-500 hover:text-red-600 dark:hover:text-red-400 transition p-1 -mt-1 -mr-1"
                                  title="Delete card"
                                >
                                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                                  </svg>
                                </button>
                              </div>
                            </div>
                          )}
                        </Draggable>
                      ))}
                      {provided.placeholder}
                    </div>

                    {showNewCard === list.id ? (
                      <form onSubmit={(e) => handleCreateCard(e, list.id)} className="mt-2">
                        <input
                          type="text"
                          value={newCardTitle}
                          onChange={(e) => setNewCardTitle(e.target.value)}
                          placeholder="Enter card title..."
                          autoFocus
                          className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 dark:bg-gray-900 dark:text-white rounded-md mb-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                        <div className="flex gap-2">
                          <button
                            type="submit"
                            className="px-3 py-1 bg-blue-600 hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 text-white rounded text-sm"
                          >
                            Add
                          </button>
                          <button
                            type="button"
                            onClick={() => {
                              setShowNewCard(null);
                              setNewCardTitle('');
                            }}
                            className="px-3 py-1 bg-gray-200 dark:bg-gray-600 rounded hover:bg-gray-300 dark:hover:bg-gray-500 dark:text-white text-sm"
                          >
                            Cancel
                          </button>
                        </div>
                      </form>
                    ) : (
                      <button
                        onClick={() => setShowNewCard(list.id)}
                        className="flex items-center gap-2 text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200 text-sm mt-2"
                      >
                        <Plus className="w-4 h-4" />
                        Add a card
                      </button>
                    )}
                  </div>
                  );
                }}
              </Droppable>
            ))}

            {/* Add List */}
            {showNewList ? (
              <div className="bg-gray-100 dark:bg-gray-800 rounded-lg p-3 w-72 flex-shrink-0">
                <form onSubmit={handleCreateList}>
                  <input
                    type="text"
                    value={newListTitle}
                    onChange={(e) => setNewListTitle(e.target.value)}
                    placeholder="Enter list title..."
                    autoFocus
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 dark:bg-gray-900 dark:text-white rounded-md mb-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <div className="flex gap-2">
                    <button
                      type="submit"
                      className="px-3 py-1 bg-blue-600 hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 text-white rounded text-sm"
                    >
                      Add List
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        setShowNewList(false);
                        setNewListTitle('');
                      }}
                      className="px-3 py-1 bg-gray-200 dark:bg-gray-600 rounded hover:bg-gray-300 dark:hover:bg-gray-500 dark:text-white text-sm"
                    >
                      Cancel
                    </button>
                  </div>
                </form>
              </div>
            ) : (
              <button
                onClick={() => setShowNewList(true)}
                className="bg-white/20 hover:bg-white/30 rounded-lg p-3 w-72 flex-shrink-0 flex items-center gap-2 text-white font-medium transition"
              >
                <Plus className="w-5 h-5" />
                Add a list
              </button>
            )}
          </div>
        </DragDropContext>
      </div>

      {/* Members Modal */}
      {showMembersModal && (
        <div className="fixed inset-0 bg-black/50 dark:bg-black/70 flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 w-full max-w-md max-h-[80vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-xl font-bold dark:text-white">Board Members</h3>
              <button
                onClick={() => {
                  setShowMembersModal(false);
                  setAddMemberError('');
                  setNewMemberEmail('');
                }}
                className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                ✕
              </button>
            </div>

            {/* Current Members */}
            <div className="mb-6">
              <h4 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">Current Members ({board.members.length})</h4>
              <div className="space-y-2">
                {board.members.map((member) => (
                  <div key={member.id} className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-md">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-blue-600 flex items-center justify-center text-white font-semibold">
                        {member.name.charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <div className="font-medium text-gray-800 dark:text-gray-200">{member.name}</div>
                        <div className="text-sm text-gray-500 dark:text-gray-400">{member.email}</div>
                      </div>
                    </div>
                    <span className={`px-2 py-1 rounded text-xs font-medium ${
                      member.role === 'owner' 
                        ? 'bg-purple-100 text-purple-700' 
                        : 'bg-gray-200 text-gray-700'
                    }`}>
                      {member.role}
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {/* Add Member Form */}
            <div className="border-t dark:border-gray-700 pt-4">
              <h4 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">Add Member</h4>
              {addMemberError && (
                <div className="bg-red-100 dark:bg-red-900/20 border border-red-400 dark:border-red-800 text-red-700 dark:text-red-400 px-3 py-2 rounded mb-3 text-sm">
                  {addMemberError}
                </div>
              )}
              <form onSubmit={handleAddMember} className="space-y-3">
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Email Address
                  </label>
                  <input
                    type="email"
                    value={newMemberEmail}
                    onChange={(e) => setNewMemberEmail(e.target.value)}
                    placeholder="member@example.com"
                    required
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-white rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                    User must already have an account
                  </p>
                </div>
                <button
                  type="submit"
                  className="w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 text-white rounded-md transition font-medium"
                >
                  Add Member
                </button>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* Board Settings Modal */}
      {showSettingsModal && (
        <div className="fixed inset-0 bg-black/50 dark:bg-black/70 flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 w-full max-w-md max-h-[80vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-xl font-bold dark:text-white">Board Settings</h3>
              <button
                onClick={() => setShowSettingsModal(false)}
                className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleUpdateBoard} className="space-y-4">
              <div>
                <label className="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">
                  Board Title
                </label>
                <input
                  type="text"
                  value={editTitle}
                  onChange={(e) => setEditTitle(e.target.value)}
                  required
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-white rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">
                  Description
                </label>
                <textarea
                  value={editDescription}
                  onChange={(e) => setEditDescription(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-white rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  rows={3}
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
                  Background Color
                </label>
                <div className="grid grid-cols-3 gap-3">
                  {colors.map((color) => (
                    <button
                      key={color}
                      type="button"
                      onClick={() => setEditBackground(color)}
                      className={`h-14 rounded-lg transition-all ${
                        editBackground === color 
                          ? 'ring-3 ring-offset-2 ring-blue-500 scale-105' 
                          : 'hover:scale-105'
                      }`}
                      style={{ backgroundColor: color }}
                    />
                  ))}
                </div>
              </div>

              <div className="pt-4 border-t dark:border-gray-700">
                <button
                  type="submit"
                  className="w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 text-white rounded-md transition font-medium mb-3"
                >
                  Save Changes
                </button>
                
                {board && board.members.find(m => m.id === user?.id)?.role === 'owner' && (
                  <button
                    type="button"
                    onClick={handleDeleteBoard}
                    className="w-full px-4 py-2 bg-red-600 hover:bg-red-700 dark:bg-red-500 dark:hover:bg-red-600 text-white rounded-md transition font-medium"
                  >
                    Delete Board
                  </button>
                )}
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Profile Modal */}
      {showEditProfile && (
        <div className="fixed inset-0 bg-black/50 dark:bg-black/70 flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-xl p-6 w-full max-w-md shadow-2xl">
            <h3 className="text-2xl font-bold mb-6 text-gray-900 dark:text-white">Edit Profile</h3>
            <form onSubmit={handleUpdateProfile} className="space-y-5">
              <div>
                <label className="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">
                  Name
                </label>
                <input
                  type="text"
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  required
                  className="w-full px-4 py-2.5 border border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Your name"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-2">
                  Email
                </label>
                <input
                  type="email"
                  value={user?.email || ''}
                  disabled
                  className="w-full px-4 py-2.5 border border-gray-300 dark:border-gray-600 rounded-lg bg-gray-50 dark:bg-gray-900 text-gray-500 dark:text-gray-400 cursor-not-allowed"
                />
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">Email cannot be changed</p>
              </div>

              <div className="flex gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => {
                    setShowEditProfile(false);
                    setEditName(user?.name || '');
                  }}
                  className="flex-1 px-4 py-2.5 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition font-medium"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="flex-1 px-4 py-2.5 bg-blue-600 hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 text-white rounded-lg transition font-medium shadow-sm"
                >
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
